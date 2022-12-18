@[Anyolite::SpecializeInstanceMethod("initialize", [source : String, options : Options = Options::None], [source : String, options : Regex::Options = Regex::Options::None])]
@[Anyolite::ExcludeConstant("SPECIAL_CHARACTERS")]
@[Anyolite::SpecializeInstanceMethod("match", [str, pos = 0, options = Regex::Options::None], [str : String, pos : Int32 = 0, options : Regex::Options = Regex::Options::None])]
@[Anyolite::SpecializeInstanceMethod("matches?", [str, pos = 0, options = Regex::Options::None], [str : String, pos : Int32 = 0, options : Regex::Options = Regex::Options::None])]
@[Anyolite::SpecializeInstanceMethod("match_at_byte_index", [str, byte_index = 0, options = Regex::Options::None], [str : String, byte_index : Int32 = 0, options : Regex::Options = Regex::Options::None])]
@[Anyolite::SpecializeInstanceMethod("matches_at_byte_index?", [str, byte_index = 0, options = Regex::Options::None], [str : String, byte_index : Int32 = 0, options : Regex::Options = Regex::Options::None])]
@[Anyolite::SpecializeInstanceMethod("+", [other], [other : Regex])]
@[Anyolite::SpecializeInstanceMethod("=~", [other], [other : String | Regex])]
@[Anyolite::SpecializeInstanceMethod("===", [other : String])]
@[Anyolite::ExcludeClassMethod("union")]
@[Anyolite::ExcludeClassMethod("append_source")]
@[Anyolite::SpecializeClassMethod("error?", [source], [source : String])]
@[Anyolite::SpecializeClassMethod("escape", [str], [str : String])]
@[Anyolite::SpecializeClassMethod("needs_escape?", [str : String], [str : String | Char])]
@[Anyolite::DefaultOptionalArgsToKeywordArgs]
@[Anyolite::RenameClass("Regexp")]
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
    {% if compare_versions(Crystal::VERSION, "1.6.2") > 0 %}
      @[Anyolite::Specialize]
      def initialize(@regex : ::Regex, @code : LibPCRE::Pcre, @string : String, @pos : Int32, @ovector : Int32*, @group_size : Int32)
        super
      end
    {% end %}
  end

  {% if compare_versions(Crystal::VERSION, "1.6.2") > 0 %}
    def initialize(source : String, options : Options = Options::None)
      super(_source: source, _options: options)
    end
  {% end %}

  def self.compile(str : String, options : Regex::Options = Regex::Options::None)
    self.new(str, options)
  end

  def match?(str : String, pos : Int32 = 0, options : Regex::Options = Regex::Options::None)
    matches?(str, pos, options)
  end

  def match_at_byte_index?(str : String, byte_index : Int32 = 0, options : Regex::Options = Regex::Options::None)
    matches_at_byte_index?(str, byte_index, options)
  end
end