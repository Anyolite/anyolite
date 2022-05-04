module Anyolite
  module RbArgCache
    @@block_cache : Pointer(RbCore::RbValue) | Nil = nil

    def self.get_block_cache
      if b = @@block_cache
        b
      else
        nil
      end
    end

    def self.set_block_cache(value)
      @@block_cache = value
    end

    def self.reset_block_cache
      @@block_cache = nil
    end
  end
end
