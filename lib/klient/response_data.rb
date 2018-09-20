module Klient
  class ResponseData
    attr_reader :original_response, :parsed_body, :parsed_headers, :status_code

    def body
      nil
    end

    def headers
      nil
    end

    def initialize(status_code, parsed_body)
      @status_code = status_code
      @parsed_body = parsed_body.freeze
    end

    def ok?
      (200..299).include?(status_code)
    end

    def method_missing(mth, *args, &block)
      # if mth.to_s =~ /http_(\d+)\?/
      #   status_code == $1.to_i
      # elsif @parsed_body.respond_to?(mth)
        @parsed_body.send(mth, *args, &block)
      # else
      #   super
      # end
    end

    def respond_to_missing?(mth, *args)
      mth.to_s =~ /http_(\d+)\?/ || @parsed_body.respond_to?(mth) || super
    end
  end
end
