module Anyolite
  module HelperClasses
    macro load_helper_class(rb, helper_class)
      Anyolite.wrap({{rb}}, Anyolite::HelperClasses::{{helper_class}})
    end

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