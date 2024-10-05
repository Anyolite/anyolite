{% if flag?(:anyolite_implementation_ruby_3) %}
  {% skip_file %}
{% end %}

@[Anyolite::ExcludeConstant("SPECIAL_CHARACTERS")]
@[Anyolite::ExcludeInstanceMethod("match!")]
@[Anyolite::SpecializeInstanceMethod("initialize", [source : String, options : Options = Options::None], [source : String])]
@[Anyolite::SpecializeInstanceMethod("match", [str : String, pos : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, pos : Int32 = 0])]
@[Anyolite::SpecializeInstanceMethod("matches?", [str : String, pos : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, pos : Int32 = 0])]
@[Anyolite::SpecializeInstanceMethod("match_at_byte_index", [str : String, byte_index : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, byte_index : Int32 = 0])]
@[Anyolite::SpecializeInstanceMethod("matches_at_byte_index?", [str : String, byte_index : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, byte_index : Int32 = 0])]
@[Anyolite::SpecializeInstanceMethod("+", [other], [other : Regex])]
@[Anyolite::SpecializeInstanceMethod("=~", [other], [other : String | Regex])]
@[Anyolite::SpecializeInstanceMethod("===", [other : String])]
@[Anyolite::ExcludeInstanceMethod("each_capture_group")]
@[Anyolite::ExcludeClassMethod("union")]
@[Anyolite::ExcludeClassMethod("append_source")]
@[Anyolite::SpecializeClassMethod("error?", [source], [source : String])]
@[Anyolite::SpecializeClassMethod("escape", [str], [str : String])]
@[Anyolite::SpecializeClassMethod("needs_escape?", [str : String], [str : String | Char])]
@[Anyolite::RenameClass("Regexp")]
@[Anyolite::ExcludeConstant("Engine")]
@[Anyolite::ExcludeConstant("PCRE2")]
@[Anyolite::ExcludeConstant("Error")]
@[Anyolite::ExcludeConstant("Options")]
@[Anyolite::ExcludeClassMethod("literal")]
@[Anyolite::ExcludeConstant("MatchOptions")]
@[Anyolite::ExcludeConstant("CompileOptions")]
@[Anyolite::ExcludeInstanceMethod("each_named_capture_group")]
class Regex
  @[Anyolite::SpecializeInstanceMethod("[]?", [n : Int])]
  @[Anyolite::SpecializeInstanceMethod("[]", [n : Int])]
  @[Anyolite::SpecializeInstanceMethod("byte_begin", [n = 0], [n : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("byte_end", [n = 0], [n : Int32 = 0])]
  @[Anyolite::ExcludeInstanceMethod("begin")]
  @[Anyolite::ExcludeInstanceMethod("end")]
  @[Anyolite::ExcludeInstanceMethod("pretty_print")]
  @[Anyolite::SpecializeInstanceMethod("to_s", [io : IO])]
  struct MatchData
    @[Anyolite::Specialize]
    def initialize(@regex : ::Regex, @code : LibPCRE2::Code*, @string : String, @pos : Int32, @ovector : LibC::SizeT*, @group_size : Int32)
      super
    end
  end

  def initialize(source : String, options : Options = Options::None)
    super(_source: source, _options: Regex::Options::None)
  end

  def self.compile(str : String)
    self.new(str)
  end

  def match?(str : String, pos : Int32 = 0)
    matches?(str, pos)
  end

  def match_at_byte_index?(str : String, byte_index : Int32 = 0)
    matches_at_byte_index?(str, byte_index)
  end
end
