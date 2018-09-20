require 'json'
module Klient
  class Response
    attr_reader :original_response, :parsed_body, :parsed_headers

    def body
      @original_response.body
    end

    def ok?
      (200..299).include?(status_code)
    end

    def status_code
      @original_response.code
    end

    def headers
      @parsed_headers
    end

    def initialize(original_response)
      @original_response = original_response
      @body = original_response.body

      if original_response.body.to_s.empty?
        @parsed_body = OpenStruct.new
      else
        @parsed_body = JSON.parse(original_response.body, object_class: OpenStruct)
      end

      @parsed_headers = OpenStruct.new(original_response.headers)
    end

    def method_missing(mth, *args, &block)
      if mth.to_s =~ /http_(\d+)\?/
        status_code == $1.to_i
      elsif @parsed_body.respond_to?(mth)
        @parsed_body.send(mth, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(mth, *args)
      mth.to_s =~ /http_(\d+)\?/ || @parsed_body.respond_to?(mth) || super
    end
  end
end
