module Anyolite
  module HelperClasses
    class AnyolitePointer
      property ptr : Void* = Pointer(Void).null

      @[Anyolite::Specialize]
      def initialize
        Anyolite.raise_runtime_error("Crystal pointers can not be created in Ruby")
      end

      def initialize(obj)
        @ptr = Box.box(obj)
      end

      def to_s
        @ptr.address.to_s
      end

      @[Anyolite::Exclude]
      def retrieve_ptr
        if !@ptr
          raise "Anyolite pointer was not initialized"
        else
          @ptr
        end
      end
    end
  end
end