class Hash
  def deep_get(key, obj, found = nil)
    if obj.respond_to?(:key?) && obj.key?(key)
      return obj[key]
    elsif obj.respond_to?(:each)
      obj.find { |*a| found = deep_get(key, a.last) }
      return found
    end
  end

  def deep_set(key, obj, value, found = nil)
    if obj.respond_to?(:key?) && obj.key?(key)
      obj[key] = value
      return value
    elsif obj.respond_to?(:each)
      obj.find { |*a| found = deep_set(key, a.last, value) }
      return found
    end
  end

  def method_missing(mth, *args, &block)
    m = mth.to_s

    if keys.include?(m)
      self[m]
    elsif m =~ /\S+=/
      deep_set(m.gsub(/=/, ''), self, args[0])
    else
      deep_get(m, self)
    end
  end
end
