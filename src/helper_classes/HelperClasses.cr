require "./AnyolitePointer.cr"

module Anyolite
  module HelperClasses
    macro load_helper_class(rb, helper_class)
      Anyolite.wrap({{rb}}, Anyolite::HelperClasses::{{helper_class}})
    end

    def self.load_all(rb)
      load_helper_class(rb, AnyolitePointer)
    end
  end
end
