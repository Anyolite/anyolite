module Anyolite
  module RbArgCache
    @@block_cache : Deque(Pointer(RbCore::RbValue)) = Deque(Pointer(RbCore::RbValue)).new

    def self.get_block_cache
      if @@block_cache.size > 0
        @@block_cache.last
      else
        nil
      end
    end

    def self.push_block_cache(value)
      @@block_cache.push(value)
    end

    def self.pop_block_cache
      @@block_cache.pop
    end
  end
end
