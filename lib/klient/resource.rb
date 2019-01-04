require_relative "resource_methods"
require_relative "resource_collection"
require 'pry'
module Klient
  class Resource
    attr_reader :collection_accessor, :header_proc, :headers, :id, :last_response, :parent, :status, :url, :url_arguments, :url_template,:root

    class << self
      attr_reader :collection_accessor, :id, :identifier, :mapping, :url_template
      attr_accessor :arguments, :resource_type, :type
    end

    extend ResourceMethods

    def initialize(parent)
      @root = parent.root
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
      "#<#{self.class.name}:#{object_id} @url=#{self.url.inspect} @status_code=#{self.last_response.try(:status) || 'nil'}>"
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
          RestClient.send(mth, url, doc, @headers)
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

      klass_type = self.class.resource_type

      if klass_type == self.class
        klass = self.class.new(parent)
      else
        klass = self.class.resource_type.new(@root)
      end

      if klass_type != self.class
        if match = klass.url_template.match(resp.request.args[:url])
          klass.url_arguments[klass.id] = match.mapping.with_indifferent_access[klass.id]
        end
      else
        if match = self.url_template.match(resp.request.args[:url])
          klass.url_arguments[klass.id] = match.mapping.with_indifferent_access[klass.id]
        end
      end

      if parsed.is_a?(Hash) && parsed.keys.any? { |k| k.to_sym == @root.collection_accessor }
        klass.url_arguments[klass.id]= parsed[klass.id]
        klass.instance_variable_set(:@last_response, Response.new(resp))
        return klass
      elsif key = parsed.keys.find { |k| k.to_s =~ @regexp }
        if parsed[key].is_a?(Array)
          arr = parsed[key].map! do |res|
            tmp = klass_type.new(@root)
            # TODO: Ugly. Revisit after recursive lookup.
            tmp.url_arguments[klass.id]= res.send(klass.id) || res.send(klass.collection_accessor).try(klass.id)

            processed = Response.new(resp, res)
            tmp.instance_variable_set(:@last_response, processed)

            tmp.instance_variable_set(:@parsed_body, processed.parsed_body)
            tmp.instance_variable_set(:@status, processed.status)
            tmp
          end
          return Klient::ResourceCollection.new(arr)
        else
          klass.url_arguments[klass.id]= parsed.send(klass.id) if klass.id
          klass.instance_variable_set(:@last_response, Response.new(resp))
          return klass
        end
      elsif self.class.type == :resource
        klass.url_arguments[klass.id]= parsed.send(klass.id) if klass.id
        klass.instance_variable_set(:@last_response, Response.new(resp))
        return klass
      elsif klass.url_arguments[klass.id]
        klass.url_arguments[klass.id]= parsed.send(klass.id)
        klass.instance_variable_set(:@last_response, Response.new(resp))
        return klass
      else
        if parsed.is_a?(Array)
          arr = parsed
        elsif parsed.keys.length == 1 && parsed[parsed.keys.first].is_a?(Array)
          arr = parsed[parsed.keys.first]
        else
          parsed.keys.each do |k|
            if parsed[k].is_a?(Array) && parsed[k].first && parsed[k].first.send(klass.id.to_sym)
              arr = parsed[k]
              break
            end
          end
        end

        arr.map! do |res|
          tmp = klass_type.new(@root)
          # TODO: Ugly. Revisit after recursive lookup.
          tmp.url_arguments[klass.id]= res.send(klass.id) || res.send(klass.collection_accessor).try(klass.id)

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
