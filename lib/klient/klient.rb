require 'rest-client'
require_relative "resource"
require_relative "resource_methods"

module Klient
  attr_reader :base_url, :header_proc, :collection_accessor, :headers, :collection_key, :url_template

  module KlientClassMethods
    attr_reader :header_proc
    include ResourceMethods
  end

  def self.included(klass)
    klass.extend(KlientClassMethods)
    klass.send(:attr_reader, :header_proc)
  end

  def initialize(base_url)
    @header_proc = self.class.header_proc
    @collection_accessor = self.class.instance_variable_get(:@collection_accessor)
    @base_url = base_url
    @headers = headers
    @url_template = Addressable::Template.new(base_url)
  end

  alias url base_url
end
