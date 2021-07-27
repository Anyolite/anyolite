{% if flag?(:anyolite_implementation_mruby_3) %}
  require "./implementations/mruby/Implementation.cr"
{% elsif flag?(:anyolite_implementation_ruby_3) %}
  require "./implementations/mri/Implementation.cr"
{% else %}
  # Default is mruby 3
  require "./implementations/mruby/Implementation.cr" 
{% end %}