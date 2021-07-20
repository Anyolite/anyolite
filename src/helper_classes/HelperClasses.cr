require "./AnyolitePointer.cr"

# TODO: AnyoliteArray
# TODO: AnyoliteHash

module Anyolite
  module HelperClasses
    def self.load_all(rb)
      load_helper_class(rb, AnyolitePointer)
    end
  end
end