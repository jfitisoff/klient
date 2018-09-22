require_relative "resource_methods"
require 'rest-client'

module Klient
  class Resource
    attr_reader :collection_accessor, :headers, :last_response, :parent, :url, :url_arguments, :url_template

    class << self
      attr_reader :collection_accessor, :identifier, :url_template
    end

    extend ResourceMethods

    def attributes
      @last_response.try(:parsed_body) || OpenStruct.new
    end

    def initialize(parent)
      @collection_accessor = parent.collection_accessor
      @identifier = self.class.try(:identifier)
      if @identifier
        @url_arguments = {@identifier => nil}
      else
        @url_arguments = {}
      end
      @parent = parent
      @headers = @parent.headers
      @url_template = Addressable::Template.new(
        @parent.url + self.class.url_template.pattern
      )
    end

    def inspect
      "#<#{self.class.name}:#{object_id} @url=#{self.url.inspect}>"
    end

    %i(delete get head).each do |mth|
      define_method(mth) do |identifier = nil, **params|
        if params.empty?
          hsh = @headers
        else
          hsh = @headers.merge({params: params})
        end

        if identifier
          out = process_raw_response(
            RestClient.send(
              mth,
              @url_template.expand(@url_arguments.keys.first => identifier).to_s,
              hsh
            )
          )
        else
          out = process_raw_response(
            RestClient.send(mth, url, hsh)
          )
        end

        if respond_to?(:last_response) && out.respond_to?(:last_response)
          @last_response = out.last_response
        end

        out
      end
    end

    %i(post put).each do |mth|
      define_method(mth) do |identifier = nil, doc, **params|
        if params.empty?
          hsh = @headers
        else
          hsh = @headers.merge({params: params})
        end

        out = process_raw_response(
          RestClient.send(mth, url, doc.to_json, hsh)
        )

        if respond_to?(:last_response) && out.respond_to?(:last_response)
          @last_response = out.last_response
        end

        out
      end
    end

    # TODO: Need a better approach.
    def method_missing(mth, *args, &block)
      # if mth.to_s =~ /^http_(\d{3})\?$/
      #   status_code == $1.to_i
      # else
        @last_response.send(mth, *args, &block)
      # end
    end

    # def respond_to_missing?(mth, *args)

      # mth.to_s =~ /^http_\d{3}\?$/ || @last_response.respond_to?(mth)
    # end

    # def method_missing(mth, *args, &block)
    #   if @last_response.respond_to?(mth)
    #     @last_response.send(mth, *args, &block)
    #   else
    #     super
    #   end
    # end

    # def respond_to_missing?(mth, *args)
    #   @last_response.respond_to?(mth)
    # end

    # TODO: Should be a getter.
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

    # Assumes JSON for the moment.
    # Doesn't yet cover case where the resource doesn't itself define a business
    # object but instead returns a preexisting one.
    def process_raw_response(resp)
      doc = JSON.parse(resp.body, object_class: OpenStruct)

      if @collection_accessor
        if data = doc.try(@collection_accessor)
          if data.is_a?(Array)
            data.map! do |res|
              tmp = self.class.new(parent)
              # TODO: Ugly. Revisit after recursive lookup.
              tmp.url_arguments[@identifier]= res.send(@identifier) ||
                res.send(@collection_accessor).try(@identifier)

              tmp.instance_variable_set(
                :@last_response,
                ResponseData.new(resp.code, res)
              )
              tmp
            end

            return data
          else
            tmp = self.class.new(parent)
            if @identifier
              tmp.url_arguments[@identifier]= doc.send(@identifier)
            end

            tmp.instance_variable_set(
              :@last_response,
              Response.new(resp)
            )

            return tmp
          end
        else
          tmp = self.class.new(parent)
          tmp.url_arguments[@identifier]= doc.send(@identifier)

          tmp.instance_variable_set(
            :@last_response,
            Response.new(resp)
          )

          return tmp
        end
      else
        raise "Must define a default collection accessor right now."
      end
    end
  end
end
