module Klient
  class ResourceCollection
    attr_reader :members, :last_response

    def initialize(arr)
      @members = arr
    end

    def method_missing(mth, *args, &block)
      @members.send(mth, *args, &block)
    end

    def respond_to?(mth, *args, &block)
      super || @members.respond_to?(mth)
    end
  end
end
