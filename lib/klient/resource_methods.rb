module ResourceMethods
  def default_collection_accessor(sym)
    @collection_accessor = sym
  end

  def resource(name, template = nil, &block)
    klass_name = name.to_s.camelcase

    if block && block.parameters.length > 1
      raise ArgumentError, "block argument should be a single resource identifier."
    end

    klass = Class.new(Klient::Resource) do
      if template
        @url_template = Addressable::Template.new(template)
      elsif block && block.parameters[0]
        @identifier = block.parameters[0][1]
        @url_template = Addressable::Template.new(
          "/#{name}{/#{@identifier}}"
        )
      else
        @url_template = Addressable::Template.new(
          "/#{name}"
        )
      end

      class_eval(&block) if block
    end
    const_set(klass_name, klass)

    define_method(name) do
      klass.new(self)
    end
  end
end
