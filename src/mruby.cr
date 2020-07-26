require "./mruby_internal.cr"

require "./mrb_state.cr"
require "./mrb_class.cr"
require "./mrb_cast.cr"

require "./format_string.cr"

alias MrbFunc = Proc(MRubyInternal::MrbState*, MRubyInternal::MrbValue, MRubyInternal::MrbValue)