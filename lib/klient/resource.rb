require_relative "resource_methods"
require 'rest-client'
RestClient.log = 'stdout'

module Klient
  class Resource
    attr_reader :identifier, :name, :parent, :headers, :url_template

    class << self
      attr_reader :identifier, :url_template
    end

    extend ResourceMethods

    def initialize(parent)
      @identifier = self.class.try(:identifier)
      @parent = parent
      @headers = @parent.headers
      @url_template = Addressable::Template.new(
        @parent.url_template.pattern + self.class.url_template.pattern
      )
    end

    def get(identifier = nil, params = {})
      if identifier
        url = @url_template.expand(@identifier => identifier.to_s).to_s
      else
        url = @url_template.expand(params).to_s
      end
      RestClient.get(url)
    end

    def post(doc, params = {})
# binding.pry
#       if identifier
#         url = @url_template.expand(@identifier => identifier.to_s).to_s
#       else
#         url = @url_template.expand(params).to_s
#       end

      RestClient.post(@url_template.expand(params).to_s, doc, @headers)
    end
  end
end
