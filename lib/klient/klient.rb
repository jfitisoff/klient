require_relative "resource"
require_relative "resource_methods"
module Klient
  attr_reader :base_url, :headers, :url_template

  def self.included(klass)
    klass.extend(KlientClassMethods)
  end

  module KlientClassMethods
    include  ResourceMethods
  #   def resource(name, template = nil, &block)
  #     klass_name = name.to_s.camelcase
  #
  #     klass = Class.new(Klient::Resource) do
  #       if template
  #         @url_template = Addressable::Template.new(template)
  #       else
  #         @url_template = Addressable::Template.new(
  #           '/' + name.to_s
  #         )
  #       end
  #
  #       class_eval(&block) if block
  #     end
  #     const_set(klass_name, klass)
  #
  #     define_method(name) do
  #       klass.new self#(@site, parse_args(args))
  #     end
  #   end
  #   alias collection resource
  end

  def initialize(base_url, headers = {})
    @base_url = base_url
    @headers = headers
    @url_template = Addressable::Template.new(base_url)
  end
end
