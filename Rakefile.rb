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

task :build_shard => [:load_config, :install_mruby, :build_mruby, :build_glue]

GLUE_FILES = ["return_functions", "data_helper", "script_helper", "error_helper"]

ANYOLITE_COMPILER = determine_compiler

# TODO: Make a config class
task :load_config do
    # Default config
    $config_ANYOLITE_BUILDPATH = "build"
    $config_ANYOLITE_MRUBY_FORK = "https://github.com/mruby/mruby"
    $config_ANYOLITE_MRUBY_RELEASE = "3.0.0"
    $config_ANYOLITE_MRUBY_DIR = "third_party"
    $config_ANYOLITE_MRUBY_CONFIG_PATH = "utility/mruby_build_config.rb"
    $config_ANYOLITE_COMPILER = determine_compiler

    config_file = get_value("ANYOLITE_CONFIG_PATH", "config_anyolite.json")

    if File.exist?(config_file) then 
        File.open(config_file, "r") do |f|
            content = JSON.parse(f)
            $config_ANYOLITE_BUILDPATH = content["ANYOLITE_BUILDPATH"] if content["ANYOLITE_BUILDPATH"]
            $config_ANYOLITE_MRUBY_FORK = content["ANYOLITE_MRUBY_FORK"] if content["ANYOLITE_MRUBY_FORK"]
            $config_ANYOLITE_MRUBY_RELEASE = content["ANYOLITE_MRUBY_RELEASE"] if content["ANYOLITE_MRUBY_RELEASE"]
            $config_ANYOLITE_MRUBY_DIR = content["ANYOLITE_MRUBY_DIR"] if content["ANYOLITE_MRUBY_DIR"]
            $config_ANYOLITE_MRUBY_CONFIG_PATH = content["ANYOLITE_MRUBY_CONFIG_PATH"] if content["ANYOLITE_MRUBY_CONFIG_PATH"]
            $config_ANYOLITE_COMPILER = content["ANYOLITE_COMPILER"] if content["ANYOLITE_COMPILER"]
        end
    else
        puts "Anyolite config file at #{config_file} not found. Default settings are used."
    end
end

task :install_mruby do
    FileUtils.mkdir_p($config_ANYOLITE_BUILDPATH)

    unless File.exist?("#{$config_ANYOLITE_MRUBY_DIR}/mruby/Rakefile")
        system "git clone #{$config_ANYOLITE_MRUBY_FORK} --branch #{$config_ANYOLITE_MRUBY_RELEASE} --recursive #{$config_ANYOLITE_MRUBY_DIR}/mruby"
    end
end

task :build_mruby do
    temp_path = Dir.pwd
    if ANYOLITE_COMPILER == :msvc
        system "cd #{$config_ANYOLITE_MRUBY_DIR}/mruby & ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config_ANYOLITE_BUILDPATH}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config_ANYOLITE_MRUBY_CONFIG_PATH}\""
    elsif ANYOLITE_COMPILER == :gcc
        system "cd #{$config_ANYOLITE_MRUBY_DIR}/mruby; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config_ANYOLITE_BUILDPATH}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config_ANYOLITE_MRUBY_CONFIG_PATH}\""
    else
        system "cd #{$config_ANYOLITE_MRUBY_DIR}/mruby; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{$config_ANYOLITE_BUILDPATH}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{$config_ANYOLITE_MRUBY_CONFIG_PATH}\""
    end
end

task :build_glue do
    FileUtils.mkdir_p($config_ANYOLITE_BUILDPATH + "/glue")

    if ANYOLITE_COMPILER == :msvc
        GLUE_FILES.each do |name|
            system "cl /I #{$config_ANYOLITE_MRUBY_DIR}/mruby/include /D MRB_INT64 /c glue/#{name}.c /Fo\"#{$config_ANYOLITE_BUILDPATH}/glue/#{name}.obj\""
        end
    elsif ANYOLITE_COMPILER == :gcc
        GLUE_FILES.each do |name|
            system "cc -std=c99 -I#{$config_ANYOLITE_MRUBY_DIR}/mruby/include -DMRB_INT64 -c glue/#{name}.c -o #{$config_ANYOLITE_BUILDPATH}/glue/#{name}.o"
        end
    else
        GLUE_FILES.each do |name|
            system "#{$config_ANYOLITE_COMPILER.to_s} -std=c99 -I#{$config_ANYOLITE_MRUBY_DIR}/mruby/include -DMRB_INT64 -c glue/#{name}.c -o #{$config_ANYOLITE_BUILDPATH}/glue/#{name}.o"
        end
    end
end
