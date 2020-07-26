require "./anyolite.cr"

def dummy_method(a, b, c)

end

MrbState.create do |mrb|
  test_class = MrbClass.new(mrb, "Test")

  p = MrbFunc.new do |mrb, self|
    MrbCast.return_bool(false)
  end

  mrb.define_method("foo", test_class, p)

  puts FormatString.generate(->dummy_method(Int32, Bool, String))

  mrb.load_string("a = Test.new.foo; puts a")
end
