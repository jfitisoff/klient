require_relative "resource_methods"
require_relative "resource_collection"

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
      @regexp = /#{self.class.name.demodulize.underscore.gsub(/(_|-|\s+)/, "(_|-|\s*)")}/i
      @collection_accessor = self.class.try(:identifier)
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
          hsh = @headers.merge(params: params)
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
          out = process_raw_response(RestClient.send(mth, url, hsh))
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

    # TODO: Bandaid just to get the initial stuff working to some extent.
    def method_missing(mth, *args, &block)
      @last_response.send(mth, *args, &block)
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

    # Assumes JSON for the moment.
    # TODO: Mechanism for determining what kind of resource to create and return.
    def process_raw_response(resp)
      doc = JSON.parse(resp.body, object_class: OpenStruct)
      hsh = JSON.parse(resp.body)

      # TODO: Rewrite
      if ridentifier = @url_template.match(resp.request.args[:url]).mapping[@identifier]
        tmp = self.class.new(parent)
        tmp.url_arguments[@identifier]= doc.send(ridentifier)

        tmp.instance_variable_set(
          :@last_response,
          Response.new(resp)
        )

        if key = hsh.keys.find { |k| k.to_s =~ @regexp }
          data = doc.send(key)[0]
          tmp.instance_variable_set(
            :@parsed_body,
            data
          )
        end

        return tmp
      elsif key = hsh.keys.find { |k| k.to_s =~ @regexp }
        if data = doc[key]
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

              tmp.instance_variable_set(
                :@parsed_body,
                data
              )
              tmp
            end
            return Klient::ResourceCollection.new(data)
          else
            tmp = self.class.new(parent)
            if @identifier
              tmp.url_arguments[@identifier]= doc.send(@identifier)
            end

            tmp.instance_variable_set(
              :@last_response,
              Response.new(resp)
            )

            if key = hsh.keys.find { |k| k.to_s =~ @regexp }
              data = doc.send(key)[0]
              tmp.instance_variable_set(
                :@parsed_body,
                data
              )
            end

            tmp.url_arguments[@identifier]= doc.send(@identifier)
            return tmp
          end
        elsif @collection_accessor
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
              return Klient::ResourceCollection.new(data)
              # return data
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
      elsif doc.is_a?(Array)
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
        return Klient::ResourceCollection.new(data)
      elsif doc.try(:keys) && doc.keys.length == 0 and doc[doc.keys.first].is_a?(Array)
        data = doc[doc.keys.first]

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

        return Klient::ResourceCollection.new(data)
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
    end
  end
end
