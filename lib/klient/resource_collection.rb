module Klient
  class ResourceCollection
    attr_reader :members
    include Enumerable

    def [](num)
      self.class.new(@members[num])
    end

    def each(&block)
      @members.each do |member|
        block.call(member)
      end
    end

    def initialize(arr)
      @members = arr
    end
  end
end
