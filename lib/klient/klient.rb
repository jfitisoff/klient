require_relative "resource"
require_relative "resource_methods"
module Klient
  attr_reader :base_url, :headers, :collection_key, :url_template

  # class << self
  #   attr_reader :collection_accessor
  # end

  def self.included(klass)
    klass.extend(KlientClassMethods)
  end

  module KlientClassMethods
    include ResourceMethods
  end

  def initialize(base_url, headers = {})
# binding.pry
    @collection_accessor = self.class.instance_variable_get(:@collection_accessor)
    @base_url = base_url
    @headers = headers
    @url_template = Addressable::Template.new(base_url)
  end
end
