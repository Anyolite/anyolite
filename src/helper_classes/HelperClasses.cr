require "./AnyolitePointer.cr"
require "./Regex.cr"

module Anyolite
  module HelperClasses
    macro load_helper_class(rb, helper_class)
      Anyolite.wrap({{rb}}, Anyolite::HelperClasses::{{helper_class}})
    end

    def self.load_all(rb)
      load_helper_class(rb, AnyolitePointer)

      # We don't need two conflicting Regex classes in MRI
      {% unless flag?(:anyolite_implementation_ruby_3) %}
        Anyolite.wrap(rb, Regex)
      {% end %}
    end
  end
end
