require 'rest-client'
require_relative "resource"
require_relative "resource_methods"

module Klient
  attr_reader :base_url, :header_proc, :collection_accessor, :headers, :collection_key, :url_template, :root

  module KlientClassMethods
    attr_reader :header_proc, :resource_map

    include ResourceMethods
  end

  def self.included(klass)
    klass.extend(KlientClassMethods)
    klass.send(:attr_reader, :header_proc)
    klass.send(:attr_reader, :resource_map)
    klass.send(:attr_reader, :identifier_map)
    klass.instance_variable_set(:@resource_map, {})
    klass.instance_variable_set(:@identifier_map, {})
  end

  def initialize(base_url)
    @root = self
    @header_proc = self.class.header_proc
    @collection_accessor = self.class.instance_variable_get(:@collection_accessor)
    @base_url = base_url
    @headers = headers
    @url_template = Addressable::Template.new(base_url)

    rmap = {}
    self.class::Resource.descendants
      .select { |x| x.name.split('::').length == 2 }
      .sort   { |x, y| x.name.demodulize <=> y.name.demodulize }
      .each do |klass|
        next unless klass.id
        cname = klass.name.demodulize.underscore.singularize.to_sym
        cname_plural = klass.name.demodulize.underscore.pluralize.to_sym

        if rmap.include?(cname)
          next
        else
          rmap[cname_plural] = klass
          rmap[cname] = klass
        end
      end

    imap = {}
    rmap.values.each do |klass|
      next unless klass.id
      imap[klass.id] = klass
    end

    @resource_map = rmap
    @identifier_map = imap

    self.class::Resource.descendants.each do |rklass|
      cname = rklass.name.demodulize.underscore.to_sym

      if rklass && rklass.arguments && rklass.arguments[:type]
        rklass.resource_type = @resource_map[rklass.arguments[:type]]
      elsif @resource_map[rklass.arguments[:type]] && @identifier_map.key(rklass)
        rklass.resource_type = @resource_map[@identifier_map.key(rklass)]
      elsif @resource_map.values.include?(rklass)
        rklass.resource_type = rklass
      elsif @resource_map[cname]
        rklass.resource_type = @resource_map[cname]
      elsif @identifier_map[rklass.id]
        rklass.resource_type = rklass.id
      else
        rklass.resource_type = rklass
      end
    end
  end

  alias url base_url
end
