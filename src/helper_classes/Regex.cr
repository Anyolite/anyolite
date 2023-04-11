{% if flag?(:anyolite_implementation_ruby_3) %}
  {% skip_file %}
{% end %}

@[Anyolite::ExcludeConstant("SPECIAL_CHARACTERS")]
{% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
  @[Anyolite::SpecializeInstanceMethod("initialize", [source : String, options : CompileOptions = CompileOptions::None], [source : String, options : Regex::CompileOptions = Regex::CompileOptions::None])]
  @[Anyolite::SpecializeInstanceMethod("match", [str, pos = 0, options = Regex::MatchOptions::None], [str : String, pos : Int32 = 0, options : Regex::MatchOptions = Regex::MatchOptions::None])]
  @[Anyolite::SpecializeInstanceMethod("matches?", [str, pos = 0, options = Regex::MatchOptions::None], [str : String, pos : Int32 = 0, options : Regex::MatchOptions = Regex::MatchOptions::None])]
  @[Anyolite::SpecializeInstanceMethod("match_at_byte_index", [str, byte_index = 0, options = Regex::MatchOptions::None], [str : String, byte_index : Int32 = 0, options : Regex::MatchOptions = Regex::MatchOptions::None])]
  @[Anyolite::SpecializeInstanceMethod("matches_at_byte_index?", [str, byte_index = 0, options = Regex::MatchOptions::None], [str : String, byte_index : Int32 = 0, options : Regex::MatchOptions = Regex::MatchOptions::None])]
{% else %}
  @[Anyolite::SpecializeInstanceMethod("initialize", [source : String, options : Options = Options::None], [source : String, options : Regex::Options = Regex::Options::None])]
  @[Anyolite::SpecializeInstanceMethod("match", [str, pos = 0, options = Regex::Options::None], [str : String, pos : Int32 = 0, options : Regex::Options = Regex::Options::None])]
  @[Anyolite::SpecializeInstanceMethod("matches?", [str, pos = 0, options = Regex::Options::None], [str : String, pos : Int32 = 0, options : Regex::Options = Regex::Options::None])]
  @[Anyolite::SpecializeInstanceMethod("match_at_byte_index", [str, byte_index = 0, options = Regex::Options::None], [str : String, byte_index : Int32 = 0, options : Regex::Options = Regex::Options::None])]
  @[Anyolite::SpecializeInstanceMethod("matches_at_byte_index?", [str, byte_index = 0, options = Regex::Options::None], [str : String, byte_index : Int32 = 0, options : Regex::Options = Regex::Options::None])]
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
@[Anyolite::ExcludeConstant("Options")]
@[Anyolite::ExcludeConstant("PCRE2")]
class Regex
  @[Anyolite::SpecializeInstanceMethod("[]?", [n : Int])]
  @[Anyolite::SpecializeInstanceMethod("[]", [n : Int])]
  @[Anyolite::SpecializeInstanceMethod("byte_begin", [n = 0], [n : Int32 = 0])]
  @[Anyolite::SpecializeInstanceMethod("byte_end", [n = 0], [n : Int32 = 0])]
  @[Anyolite::ExcludeInstanceMethod("begin")]
  @[Anyolite::ExcludeInstanceMethod("end")]
  @[Anyolite::ExcludeInstanceMethod("pretty_print")]
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

  {% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
    def initialize(source : String, options : CompileOptions = CompileOptions::None)
      super(_source: source, _options: options)
    end
  {% elsif compare_versions(Crystal::VERSION, "1.6.2") > 0 %}
    def initialize(source : String, options : Options = Options::None)
      super(_source: source, _options: options)
    end
  {% end %}

  {% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
  {% else %}
    def self.compile(str : String, options : Regex::Options = Regex::Options::None)
      self.new(str, options)
    end
  {% end %}

  {% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
  {% else %}
    def match?(str : String, pos : Int32 = 0, options : Regex::Options = Regex::Options::None)
      matches?(str, pos, options)
    end
  {% end %}

  {% if compare_versions(Crystal::VERSION, "1.7.3") > 0 %}
  {% else %}
    def match_at_byte_index?(str : String, byte_index : Int32 = 0, options : Regex::Options = Regex::Options::None)
      matches_at_byte_index?(str, byte_index, options)
    end
  {% end %}
end
