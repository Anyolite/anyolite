module MrbWrap

    def self.instance_method(mrb : MrbState, crystal_class : Class, name : String, method)
        format_string = FormatString.get(method)

        mruby_method = MrbFunc.new do |mrb, self|
            # TODO: Format String using Macros
        end

        mrb.define_method(name: name, proc: mruby_method)
    end

end