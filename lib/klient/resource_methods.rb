module ResourceMethods
  def default_collection_accessor(sym)
    @collection_accessor = sym
  end

  def collection(name, template = nil, **hash_args, &block)
    klass_name = name.to_s.camelcase

    unless hash_args[:identifier]
      raise ArgumentError, "Collection must specify a resource identifier."
    end

    klass = Class.new(Klient::Resource) do
      # TODO: Avoid identifier conflicts between hash and URL template.
      if template
        @url_template = Addressable::Template.new(template)
        # TODO: clean this up
        @identifier = hash_args[:identifier]
      elsif hash_args[:identifier]
        @identifier = hash_args[:identifier]
        @url_template = Addressable::Template.new(
          "/#{name}{/#{@identifier}}"
        )
      end

      class_eval(&block) if block
    end
    const_set(klass_name, klass)

    define_method(name) do
      klass.new(self)
    end
  end

  def resource(name, template = nil, &block)
    klass_name = name.to_s.camelcase

    klass = Class.new(Klient::Resource) do
      # TODO: Avoid identifier conflicts between hash and URL template.
      if template
        @url_template = Addressable::Template.new(template)
      else
        @identifier = nil
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

  def resources(*resource_names)
    resource_names.each { |rname| resource rname }
  end
end
