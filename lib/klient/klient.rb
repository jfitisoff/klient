require 'rest-client'
require_relative "resource"
require_relative "resource_methods"
# require_relative "resource_collection"

module Klient
  # SUBSTITUTION = "(_|-|\s*)"
  attr_reader :base_url, :collection_accessor, :headers, :collection_key, :url_template

  module KlientClassMethods
    include ResourceMethods
  end

  def self.included(klass)
    klass.extend(KlientClassMethods)
  end

  def initialize(base_url, headers = {})
    @collection_accessor = self.class.instance_variable_get(:@collection_accessor)
    @base_url = base_url
    @headers = headers
    @url_template = Addressable::Template.new(base_url)
  end

  alias url base_url
end
