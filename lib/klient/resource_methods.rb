module ResourceMethods
  def default_collection_accessor(sym)
    @collection_accessor = sym
  end

  def headers(&block)
    @header_proc = block
  end

  def collection(name, template = nil, **hash_args, &block)
    klass_name = name.to_s.camelcase

    klass = Class.new(Klient::Resource) do
      @arguments = hash_args
      @type = :collection

      # Obtain the collection's resource identifier. Don't allow hash arg AND block
      # param for same thing -- it has to be either one or the other.
      if block_given? && block.arity > 0 && hash_args[:identifier]
        raise ArgumentError, "Collection identifier for :#{name} can be specified as a " \
        "hash argument OR a block parameter (You can't use both simultaneously.)"
      elsif block_given? && block.arity > 0
        @id = block.parameters[0][1]
      elsif hash_args[:identifier]
        @id = hash_args[:identifier]
      else
        # raise ArgumentError, "#{name} collection definition does not specify a resource identifier."
      end

      # Don't allow templates with variables.
      if template && template =~ /[\{\}]/
        raise ArgumentError, "URL template variables not supported."
      end

      # Build a URL template if the template arg was provided.
      if template && id
        @url_template = Addressable::Template.new(template.to_s + "{/#{id}}")
      elsif id
        @identifier = nil
        @url_template = Addressable::Template.new("/#{name}{/#{id}}")
      else
        @identifier = nil
        @url_template = Addressable::Template.new("/#{name}")
      end

      # # Build a URL template if the template arg was provided.
      # if template && id
      #   @url_template = Addressable::Template.new(template.to_s + "{/#{id}}")
      # else
      #   @identifier = nil
      #   @url_template = Addressable::Template.new("/#{name}{/#{id}}")
      # end

      class_eval(&block) if block
    end
    const_set(klass_name, klass)

    define_method(name) do
      klass.new(self)
    end
  end

  def resource(name, template = nil, **hash_args, &block)
    klass_name = name.to_s.camelcase

    klass = Class.new(Klient::Resource) do
      @arguments = hash_args
      @type = :resource

      # TODO: Avoid identifier conflicts between hash and URL template.
      if template
        @url_template = Addressable::Template.new(template)
      else
        @identifier = nil
        @url_template = Addressable::Template.new("/#{name}")
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
