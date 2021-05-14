require 'fileutils'
require 'json'

def get_value(env_var_name, default)
    ENV[env_var_name] ? ENV[env_var_name] : default
end

def determine_compiler
    if ENV["VisualStudioVersion"] || ENV["VSINSTALLDIR"]
        return :msvc
    else
        return :gcc
    end
end

class AnyoliteConfig
    OPTIONS = {
        :build_path => "build", 
        :rb_fork => "https://github.com/mruby/mruby",
        :rb_release => "3.0.0",
        :rb_dir => "third_party", 
        :rb_config => "utility/mruby_build_config.rb", 
        :glue_dir => "glue/mrb3",
        :compiler => determine_compiler
    }

    OPTIONS.each_key{|option| attr_reader option}

    def initialize
        OPTIONS.each_key{|option| set_option(option, OPTIONS[option])}
    end
    
    def load(config_file)
        if File.exist?(config_file) then 
            File.open(config_file, "r") do |f|
                content = JSON.load(f)
                OPTIONS.each_key {|option| read_option(content, option)}
            end
        else
            puts "Anyolite config file at #{config_file} not found. Default settings are used."
        end
    end

    def read_option(content, name)
        read_value = content["ANYOLITE_#{name.to_s.upcase}"]
        set_option(name, read_value) if read_value
    end

    def set_option(name, value)
        self.instance_variable_set("@#{name}".to_sym, value)
    end
end

task :build_shard => [:load_config, :install_mruby, :build_mruby, :build_glue]
task :recompile_glue => [:load_config, :build_glue]
task :recompile => [:load_config, :build_mruby, :build_glue]

GLUE_FILES = ["return_functions", "data_helper", "script_helper", "error_helper"]

ANYOLITE_COMPILER = determine_compiler

$config = nil

task :load_config do
    if !$config
        $config = AnyoliteConfig.new
        config_file = get_value("ANYOLITE_CONFIG_PATH", "config_anyolite.json")
        $config.load(config_file)
    end
end

task :reload_config do
    $config = AnyoliteConfig.new
    config_file = get_value("ANYOLITE_CONFIG_PATH", "config_anyolite.json")
    $config.load(config_file)
end

task :install_mruby => [:load_config] do
    FileUtils.mkdir_p($config.build_path)

    unless File.exist?("#{$config.rb_dir}/mruby/Rakefile")
        system "git clone #{$config.rb_fork} --branch #{$config.rb_release} --recursive #{$config.rb_dir}/mruby"
    end
end

task :build_mruby => [:load_config] do
    temp_path = Dir.pwd
    if ANYOLITE_COMPILER == :msvc
        system "cd #{$config.rb_dir}/mruby & ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config.build_path}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config.rb_config}\""
    elsif ANYOLITE_COMPILER == :gcc
        system "cd #{$config.rb_dir}/mruby; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config.build_path}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config.rb_config}\""
    else
        system "cd #{$config.rb_dir}/mruby; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config.build_path}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config.rb_config}\""
    end
end

task :build_glue => [:load_config] do
    FileUtils.mkdir_p($config.build_path + "/glue")

    if ANYOLITE_COMPILER == :msvc
        GLUE_FILES.each do |name|
            system "cl /I #{$config.rb_dir}/mruby/include /D MRB_INT64 /c #{$config.glue_dir}/#{name}.c /Fo\"#{$config.build_path}/glue/#{name}.obj\""
        end
    elsif ANYOLITE_COMPILER == :gcc
        GLUE_FILES.each do |name|
            system "cc -std=c99 -I#{$config.rb_dir}/mruby/include -DMRB_INT64 -c #{$config.glue_dir}/#{name}.c -o #{$config.build_path}/glue/#{name}.o"
        end
    else
        GLUE_FILES.each do |name|
            system "#{$config.compiler.to_s} -std=c99 -I#{$config.rb_dir}/mruby/include -DMRB_INT64 -c #{$config.glue_dir}/#{name}.c -o #{$config.build_path}/glue/#{name}.o"
        end
    end
end

task :clean => [:load_config] do
    FileUtils.remove_dir($config.rb_dir, force: true)
    FileUtils.remove_dir($config.build_path, force: true)
    FileUtils.remove_entry($config.rb_config + ".lock", force: true)
end