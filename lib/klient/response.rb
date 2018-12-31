require 'json'
module Klient
  class Response
    attr_reader :original_response, :parsed_body, :parsed_headers, :status

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

    def initialize(original_response, data = nil)
      @status = original_response.code

      # If data arg is provided then it's a collection resource and the original
      # response is for the entire collection. We don't want that -- this is an
      # individual resource FOR the collection -- so the data arg is used in place
      # of the parsed body for the collection response.
      if data
        @original_response = nil
        @parsed_body = data
        @parsed_headers = nil
      else
        @original_response = original_response
        @body = @original_response.body
        @parsed_headers = @original_response.headers

        if @original_response.body.blank?
           @parsed_body = {}
        else
          @parsed_body = JSON.parse(@original_response.body)
        end
      end
    end

    # TODO: This is dangerously wrong. It's just a shortcut to get something working.
    def method_missing(mth, *args, &block)
      if mth.to_s =~ /http_(\d+)\?/
        status_code == $1.to_i
      else
        @parsed_body.send(mth)
      end
    end

    def respond_to_missing?(mth, *args)
      mth.to_s =~ /http_(\d+)\?/ || @parsed_body.respond_to?(mth) || super
    end
  end
end
