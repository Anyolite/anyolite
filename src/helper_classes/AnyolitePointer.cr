module Anyolite
  module HelperClasses
    class AnyolitePointer
      property address : UInt64 = 0

      def initialize(address : UInt64)
        @address = address
      end

      def to_s
        @address.to_s
      end
    end
  end
end