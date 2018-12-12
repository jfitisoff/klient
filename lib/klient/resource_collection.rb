module Klient
  class ResourceCollection
    attr_reader :members, :last_response

    # def [](num)
    #   self.class.new(@members[num])
    # end
    #
    # def each(&block)
    #   @members.each do |member|
    #     block.call(member)
    #   end
    # end

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
