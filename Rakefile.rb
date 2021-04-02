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

task :build_shard => [:load_config, :install_ruby, :build_ruby, :build_glue]

GLUE_FILES = ["return_functions", "data_helper", "script_helper", "error_helper"]

ANYOLITE_COMPILER = determine_compiler

# TODO: Make a config class
task :load_config do
    # Default config
    $config_ANYOLITE_BUILDPATH = "build"
    $config_ANYOLITE_RUBY_FORK = "https://github.com/ruby/ruby"
    $config_ANYOLITE_RUBY_RELEASE = "" # "--branch v3_0_0"
    $config_ANYOLITE_RUBY_DIR = "third_party"
    $config_ANYOLITE_COMPILER = determine_compiler

    config_file = get_value("ANYOLITE_CONFIG_PATH", "config_anyolite.json")

    if File.exist?(config_file) then 
        File.open(config_file, "r") do |f|
            content = JSON.parse(f)
            $config_ANYOLITE_BUILDPATH = content["ANYOLITE_BUILDPATH"] if content["ANYOLITE_BUILDPATH"]
            $config_ANYOLITE_RUBY_FORK = content["ANYOLITE_RUBY_FORK"] if content["ANYOLITE_RUBY_FORK"]
            $config_ANYOLITE_RUBY_RELEASE = content["ANYOLITE_RUBY_RELEASE"] if content["ANYOLITE_RUBY_RELEASE"]
            $config_ANYOLITE_RUBY_DIR = content["ANYOLITE_RUBY_DIR"] if content["ANYOLITE_RUBY_DIR"]
            $config_ANYOLITE_COMPILER = content["ANYOLITE_COMPILER"] if content["ANYOLITE_COMPILER"]
        end
    else
        puts "Anyolite config file at #{config_file} not found. Default settings are used."
    end
end

task :install_ruby do
    FileUtils.mkdir_p($config_ANYOLITE_BUILDPATH)

    system "git clone #{$config_ANYOLITE_RUBY_FORK} #{$config_ANYOLITE_RUBY_RELEASE} --recursive #{$config_ANYOLITE_RUBY_DIR}/ruby"
end

task :build_ruby do
    temp_path = Dir.pwd
    if ANYOLITE_COMPILER == :msvc
        system "cd #{$config_ANYOLITE_RUBY_DIR}/ruby & ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config_ANYOLITE_BUILDPATH}/ruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config_ANYOLITE_MRUBY_CONFIG_PATH}\""
    elsif ANYOLITE_COMPILER == :gcc
        system "cd #{$config_ANYOLITE_RUBY_DIR}/ruby; autoconf; ./configure; make; make check"
    else
        system "cd #{$config_ANYOLITE_RUBY_DIR}/ruby; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config_ANYOLITE_BUILDPATH}/ruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config_ANYOLITE_MRUBY_CONFIG_PATH}\""
    end
end

task :build_glue do
    FileUtils.mkdir_p($config_ANYOLITE_BUILDPATH + "/glue")

    if ANYOLITE_COMPILER == :msvc
        GLUE_FILES.each do |name|
            system "cl /I #{$config_ANYOLITE_RUBY_DIR}/ruby/include /D MRB_INT64 /c glue/#{name}.c /Fo\"#{$config_ANYOLITE_BUILDPATH}/glue/#{name}.obj\""
        end
    elsif ANYOLITE_COMPILER == :gcc
        GLUE_FILES.each do |name|
            system "cc -std=c99 -I#{$config_ANYOLITE_RUBY_DIR}/ruby/include -I#{$config_ANYOLITE_RUBY_DIR}/ruby/include/internal -DMRB_INT64 -c glue/#{name}.c -o #{$config_ANYOLITE_BUILDPATH}/glue/#{name}.o"
        end
    else
        GLUE_FILES.each do |name|
            system "#{$config_ANYOLITE_COMPILER.to_s} -std=c99 -I#{$config_ANYOLITE_RUBY_DIR}/ruby/include -DMRB_INT64 -c glue/#{name}.c -o #{$config_ANYOLITE_BUILDPATH}/glue/#{name}.o"
        end
    end
end
