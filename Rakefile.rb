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
        :implementation => "mruby",
        :build_path => "build", 
        :rb_fork => "https://github.com/mruby/mruby",
        :rb_release => "3.1.0",
        :rb_minor => "3.1.0",
        :rb_dir => "third_party", 
        :rb_config => "utility/mruby_build_config.rb", 
        :glue_dir => "glue/mruby",
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
        read_value = content["ANYOLITE_#{name.to_s.upcase}"] || content[name.to_s]
        set_option(name, read_value) if read_value
    end

    def set_option(name, value)
        self.instance_variable_set("@#{name}".to_sym, value)
    end
end

task :build_shard => [:load_config, :install_ruby, :build_ruby, :build_glue]
task :recompile_glue => [:load_config, :build_glue]
task :recompile => [:load_config, :build_ruby, :build_glue]

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

task :install_ruby => [:load_config] do
    unless $config.rb_fork == "___EXTERNAL___"
        FileUtils.mkdir_p($config.build_path)

        unless File.exist?("#{$config.rb_dir}/#{$config.implementation}/README.md")
            system "git clone #{$config.rb_fork} --branch #{$config.rb_release} --recursive #{$config.rb_dir}/#{$config.implementation}"
        end
    end
end

# RUBY_OPT_DIR="C:/vcpkg/installed/x64-windows"
# NOTE: This will be relevant for MRI on Windows

task :build_ruby => [:load_config] do
    unless $config.rb_fork == "___EXTERNAL___"
        temp_path = Dir.pwd
        temp_rb_config_path = get_value("ANYOLITE_RB_CONFIG_RELATIVE_PATH", Dir.pwd)

        if $config.implementation == "mruby"
            if ANYOLITE_COMPILER == :msvc
                system "cd #{$config.rb_dir}/#{$config.implementation} & ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config.build_path}/#{$config.implementation}\" MRUBY_CONFIG=\"#{temp_rb_config_path}/#{$config.rb_config}\""
            elsif ANYOLITE_COMPILER == :gcc
                system "cd #{$config.rb_dir}/#{$config.implementation}; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config.build_path}/#{$config.implementation}\" MRUBY_CONFIG=\"#{temp_rb_config_path}/#{$config.rb_config}\""
            else
                system "cd #{$config.rb_dir}/#{$config.implementation}; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config.build_path}/#{$config.implementation}\" MRUBY_CONFIG=\"#{temp_rb_config_path}/#{$config.rb_config}\""
            end
        elsif $config.implementation == "mri"
            if ANYOLITE_COMPILER == :msvc
                raise "MSVC compilation of MRI is not supported yet."
                
                # TODO: Fix MRI on Windows
                # FileUtils.cp_r("#{$config.rb_dir}/#{$config.implementation}", "#{temp_path}/#{$config.build_path}/src_#{$config.implementation}")
                # FileUtils.cd "#{$config.build_path}/src_#{$config.implementation}"
                # system "./win32/configure.bat --prefix=\"#{temp_path}/#{$config.build_path}/#{$config.implementation}\" --with-opt-dir=#{RUBY_OPT_DIR}"
                # system "nmake incs"
                # system "nmake extract-extlibs"
                # system "nmake"
                # system "nmake install"
                
            elsif ANYOLITE_COMPILER == :gcc
                system "cp -r #{$config.rb_dir}/#{$config.implementation} #{temp_path}/#{$config.build_path}/src_#{$config.implementation}"
                system "cd #{$config.build_path}/src_#{$config.implementation}; ./autogen.sh"
                system "cd #{$config.build_path}/src_#{$config.implementation}; ./configure --prefix=\"#{temp_path}/#{$config.build_path}/#{$config.implementation}\""
                system "cd #{$config.build_path}/src_#{$config.implementation}; make"
                system "cd #{$config.build_path}/src_#{$config.implementation}; make install"
            else
            end
        else
            raise "Invalid ruby implementation: #{$config.implementation}. Use either \"mruby\" or \"mri\"."
        end
    end
end

task :build_glue => [:load_config] do
    FileUtils.mkdir_p($config.build_path + "/glue/#{$config.implementation}")

    if $config.rb_fork == "___EXTERNAL___" && $config.rb_dir == "___EMPTY___"
        puts "NOTE: No Ruby directory specified. Glue object files will not be built!"
    else
        if $config.implementation == "mruby"
            if ANYOLITE_COMPILER == :msvc
                GLUE_FILES.each do |name|
                    system "cl /I #{$config.rb_dir}/#{$config.implementation}/include /D MRB_INT64 /c #{$config.glue_dir}/#{name}.c /Fo\"#{$config.build_path}/glue/#{$config.implementation}/#{name}.obj\""
                end
            elsif ANYOLITE_COMPILER == :gcc
                GLUE_FILES.each do |name|
                    system "cc -std=c99 -I#{$config.rb_dir}/#{$config.implementation}/include -DMRB_INT64 -c #{$config.glue_dir}/#{name}.c -o #{$config.build_path}/glue/#{$config.implementation}/#{name}.o"
                end
            else
                GLUE_FILES.each do |name|
                    system "#{$config.compiler.to_s} -std=c99 -I#{$config.rb_dir}/#{$config.implementation}/include -DMRB_INT64 -c #{$config.glue_dir}/#{name}.c -o #{$config.build_path}/glue/#{$config.implementation}/#{name}.o"
                end
            end
        elsif $config.implementation == "mri"
            if ANYOLITE_COMPILER == :msvc
                GLUE_FILES.each do |name|
                    system "cl /I #{$config.build_path}/#{$config.implementation}/include/ruby-#{$config.rb_minor} /I #{$config.build_path}/#{$config.implementation}/include/ruby-#{$config.rb_minor}/x64-mswin64_140 /c #{$config.glue_dir}/#{name}.c /Fo\"#{$config.build_path}/glue/#{$config.implementation}/#{name}.obj\""
                end
            elsif ANYOLITE_COMPILER == :gcc
                GLUE_FILES.each do |name|
                    system "cc -std=c99 -I#{$config.build_path}/#{$config.implementation}/include/ruby-#{$config.rb_minor} -I#{$config.build_path}/#{$config.implementation}/include/ruby-#{$config.rb_minor}/x86_64-linux -I#{$config.build_path}/#{$config.implementation}/include/ruby-#{$config.rb_minor}/aarch64-linux -c #{$config.glue_dir}/#{name}.c -o #{$config.build_path}/glue/#{$config.implementation}/#{name}.o"
                end
            else
                GLUE_FILES.each do |name|
                    system "#{$config.compiler.to_s} -std=c99 -I#{$config.rb_dir}/#{$config.implementation}/include -c #{$config.glue_dir}/#{name}.c -o #{$config.build_path}/glue/#{$config.implementation}/#{name}.o"
                end
            end
        else
            raise "Invalid ruby implementation: #{$config.implementation}. Use either \"mruby\" or \"mri\"."
        end
    end
end

task :clean => [:load_config] do
    temp_path = get_value("ANYOLITE_RB_CONFIG_RELATIVE_PATH", Dir.pwd)

    FileUtils.remove_dir($config.rb_dir, force: true) unless $config.rb_fork == "___EXTERNAL___"
    FileUtils.remove_dir($config.build_path, force: true)
    FileUtils.remove_entry(temp_path + "/" + $config.rb_config + ".lock", force: true)
end