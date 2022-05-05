module Anyolite
  # Cache for mruby class and module references
  module RbClassCache
    @@cache = {} of String => RbClass | RbModule

    def self.register(crystal_class : Class, rb_class : RbClass)
      @@cache[crystal_class.name] = rb_class
    end

    def self.register(crystal_module : Class, rb_module : RbModule)
      @@cache[crystal_module.name] = rb_module
    end

    def self.get(n : Nil)
      nil
    end

    def self.get(ruby_module : RbModule)
      ruby_module
    end

    def self.get(crystal_class : Class)
      if @@cache[crystal_class.name]?
        return @@cache[crystal_class.name]
      else
        raise "Uncached class or module: #{crystal_class}"
      end
    end

    def self.check(crystal_class : Class | RbModule | Nil)
      if crystal_class.is_a?(Class)
        @@cache[crystal_class.name]?
      else
        crystal_class
      end
    end

    def self.reset
      @@cache.clear
    end
  end
end
