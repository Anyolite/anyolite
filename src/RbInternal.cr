{% if flag?(:anyolite_implementation_mruby_3) %}
  require "./implementations/Mrb3Impl/Implementation.cr"
{% elsif flag?(:anyolite_implementation_ruby_3) %}
  require "./implementations/Rb3Impl/Implementation.cr"
{% else %}
  # Default is mruby 3
  require "./implementations/Mrb3Impl/Implementation.cr" 
{% end %}