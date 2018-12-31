require_relative "resource_methods"
require_relative "resource_collection"
require 'pry'
module Klient
  class Resource
    attr_reader :collection_accessor, :header_proc, :headers, :id, :last_response, :parent, :status, :url, :url_arguments, :url_template

    class << self
      attr_reader :collection_accessor, :id, :identifier, :mapping, :url_template
    end

    extend ResourceMethods

    def initialize(parent)
      @header_proc = parent.header_proc
      @regexp = /#{self.class.name.demodulize.underscore.gsub(/(_|-|\s+)/, "(_|-|\s*)")}/i
      @id = self.class.try(:id)
      @collection_accessor = @identifier = self.class.try(:identifier)

      if @id
        @url_arguments = {@id => @identifier}
      else
        @url_arguments = {}
      end

      @parent = parent
      @headers = {}

      @url_template = Addressable::Template.new(
        @parent.url + self.class.url_template.pattern
      )
    end

    def inspect
      "#<#{self.class.name}:#{object_id} @url=#{self.url.inspect} @status_code=#{self.last_response.try(:status)}>"
    end

    %i(delete get head).each do |mth|
      define_method(mth) do |identifier = nil, **params|

        if params.empty?
          @headers = @header_proc.call
        else
          @headers = @header_proc.call.merge(params: params)
        end

        if identifier
          out = process_response(
            RestClient.send(
              mth,
              @url_template.expand(@id => identifier).to_s,
              @headers
            )
          )
        else
          out = process_response(RestClient.send(mth, url, @headers))
        end

        if respond_to?(:last_response) && out.respond_to?(:last_response)
          @last_response = out.last_response
        end

        out.instance_variable_set(:@identifier, identifier)
        out
      end
    end

    %i(post put).each do |mth|
      define_method(mth) do |identifier = nil, doc, **params|
        if params.empty?
          @headers = @header_proc.call
        else
          @headers = @header_proc.call.merge(params: params)
        end

        out = process_response(
          RestClient.send(mth, url, doc.to_json, @headers)
        )

        if respond_to?(:last_response) && out.respond_to?(:last_response)
          @last_response = out.last_response
        end

        out.instance_variable_set(:@identifier, identifier)
        out
      end
    end

    def url
      @url_template.expand(@url_arguments).to_s
    end

    private
    # Assumes JSON for the moment.
    def process_doc(doc)
      if doc.is_a?(Hash)
        doc.to_json
      elsif doc.empty?
        {}.to_json
      else
        doc
      end
    end

    def method_missing(mth, *args, &block)
      if @parsed_body.respond_to?(mth)
        @parsed_body.send(mth, *args, &block)
      else
        @last_response.send(mth, *args, &block)
      end
    end

    # EXPERIMENTAL (USING HASH MODS)
    def process_response(resp)
      parsed = JSON.parse(resp.body)#.to_data

      # TODO: Rewrite
      @mapping = @url_template.match(resp.request.args[:url]).mapping.with_indifferent_access
      tmp = self.class.new(parent)
      # It's a resource if mapping responds to id. Otherwise, it's a collection.
      if @mapping[@id] || @url_template.variables.empty? # Ugly
        tmp.url_arguments[@id]= @mapping[@id]
        tmp.instance_variable_set(:@last_response, Response.new(resp))
        return tmp
      else
        if parsed.source.is_a?(Array)
          arr = parsed
        elsif parsed.keys.length == 1 && parsed[parsed.keys.first].source.is_a?(Array)
          arr = parsed[parsed.keys.first]
        else
          parsed.keys.each do |k|
            if parsed[k].is_a?(Array) && parsed[k].first.send(@id.to_sym)
              arr = parsed[k]
              break
            end
          end
        end

        arr.map! do |res|
          tmp = self.class.new(parent)
          # TODO: Ugly. Revisit after recursive lookup.
          tmp.url_arguments[@id]= res.send(@id) || res.send(@collection_accessor).try(@id)

          processed = Response.new(resp, res)
          tmp.instance_variable_set(:@last_response, processed)

          tmp.instance_variable_set(:@parsed_body, processed.parsed_body)
          tmp.instance_variable_set(:@status, processed.status)
          tmp
        end

        return Klient::ResourceCollection.new(arr)
      end
    end
  end
end
