{% if flag?(:anyolite_implementation_ruby_3) %}
  {% skip_file %}
{% end %}

@[Anyolite::ExcludeConstant("SPECIAL_CHARACTERS")]
{% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
  {% if compare_versions(Crystal::VERSION, "1.9.0") > 0 %}
    @[Anyolite::ExcludeInstanceMethod("match!")]
  {% end %}
  @[Anyolite::SpecializeInstanceMethod("initialize", [source : String, options : Options = Options::None], [source : String])]
  @[Anyolite::SpecializeInstanceMethod("match", [str : String, pos : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, pos : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("matches?", [str : String, pos : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, pos : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("match_at_byte_index", [str : String, byte_index : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, byte_index : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("matches_at_byte_index?", [str : String, byte_index : Int32 = 0, options : Regex::MatchOptions = :none], [str : String, byte_index : Int32 = 0])]
{% else %}
  @[Anyolite::SpecializeInstanceMethod("initialize", [source : String, options : Options = Options::None], [source : String])]
  @[Anyolite::SpecializeInstanceMethod("match", [str, pos = 0, options = Regex::Options::None], [str : String, pos : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("matches?", [str, pos = 0, options = Regex::Options::None], [str : String, pos : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("match_at_byte_index", [str, byte_index = 0, options = Regex::Options::None], [str : String, byte_index : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("matches_at_byte_index?", [str, byte_index = 0, options = Regex::Options::None], [str : String, byte_index : Int32 = 0])]
{% end %}
@[Anyolite::SpecializeInstanceMethod("+", [other], [other : Regex])]
@[Anyolite::SpecializeInstanceMethod("=~", [other], [other : String | Regex])]
@[Anyolite::SpecializeInstanceMethod("===", [other : String])]
@[Anyolite::ExcludeInstanceMethod("each_capture_group")]
@[Anyolite::ExcludeClassMethod("union")]
@[Anyolite::ExcludeClassMethod("append_source")]
@[Anyolite::SpecializeClassMethod("error?", [source], [source : String])]
@[Anyolite::SpecializeClassMethod("escape", [str], [str : String])]
@[Anyolite::SpecializeClassMethod("needs_escape?", [str : String], [str : String | Char])]
@[Anyolite::DefaultOptionalArgsToKeywordArgs]
@[Anyolite::RenameClass("Regexp")]
@[Anyolite::ExcludeConstant("Engine")]
@[Anyolite::ExcludeConstant("PCRE2")]
@[Anyolite::ExcludeConstant("Error")]
@[Anyolite::ExcludeConstant("Options")]
{% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
  {% if compare_versions(Crystal::VERSION, "1.9.0") > 0 %}
    @[Anyolite::ExcludeClassMethod("literal")]
  {% end %}
  @[Anyolite::ExcludeConstant("MatchOptions")]
  @[Anyolite::ExcludeConstant("CompileOptions")]
  {% if compare_versions(Crystal::VERSION, "1.8.0") > 0 %}
    @[Anyolite::ExcludeInstanceMethod("each_named_capture_group")]
  {% end %}
{% end %}
class Regex
  @[Anyolite::SpecializeInstanceMethod("[]?", [n : Int])]
  @[Anyolite::SpecializeInstanceMethod("[]", [n : Int])]
  @[Anyolite::SpecializeInstanceMethod("byte_begin", [n = 0], [n : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("byte_end", [n = 0], [n : Int32 = 0])]
  @[Anyolite::ExcludeInstanceMethod("begin")]
  @[Anyolite::ExcludeInstanceMethod("end")]
  @[Anyolite::ExcludeInstanceMethod("pretty_print")]
  @[Anyolite::SpecializeInstanceMethod("to_s", [io : IO])]
  @[Anyolite::DefaultOptionalArgsToKeywordArgs]
  struct MatchData
    {% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
      @[Anyolite::Specialize]
      def initialize(@regex : ::Regex, @code : LibPCRE2::Code*, @string : String, @pos : Int32, @ovector : LibC::SizeT*, @group_size : Int32)
        super
      end
    {% elsif compare_versions(Crystal::VERSION, "1.6.2") > 0 %}
      @[Anyolite::Specialize]
      def initialize(@regex : ::Regex, @code : LibPCRE::Pcre, @string : String, @pos : Int32, @ovector : Int32*, @group_size : Int32)
        super
      end
    {% end %}
  end

  {% if compare_versions(Crystal::VERSION, "1.6.2") > 0 %}
    def initialize(source : String, options : Options = Options::None)
      super(_source: source, _options: Regex::Options::None)
    end
  {% end %}

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
