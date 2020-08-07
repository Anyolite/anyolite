require 'fileutils'

def get_value(env_var_name, default)
    ENV[env_var_name] ? ENV[env_var_name] : default
end

def determine_compiler
    if ENV["ANYOLITE_COMPILER"]
        return ENV["ANYOLITE_COMPILER"].lowercase.to_sym
    elsif ENV["VisualStudioVersion"] || ENV["VSINSTALLDIR"]
        return :msvc
    else
        return :gcc
    end
end

task :build_shard => [:install_mruby, :build_mruby, :build_glue]

ANYOLITE_BUILDPATH = get_value("ANYOLITE_BUILDPATH", "build")
ANYOLITE_MRUBY_FORK = get_value("ANYOLITE_MRUBY_FORK", "https://github.com/mruby/mruby")
ANYOLITE_MRUBY_DIR = get_value("ANYOLITE_MRUBY_DIR", "third_party")
ANYOLITE_MRUBY_CONFIG_PATH = get_value("ANYOLITE_MRUBY_CONFIG_PATH", "utility/mruby_build_config.rb")

GLUE_FILES = ["return_functions", "data_helper", "script_helper"]

ANYOLITE_COMPILER = determine_compiler

task :install_mruby do
    FileUtils.mkdir_p(ANYOLITE_BUILDPATH)

    unless Dir.exist?("#{ANYOLITE_MRUBY_DIR}/mruby/Rakefile")
        system "git clone #{ANYOLITE_MRUBY_FORK} --recursive #{ANYOLITE_MRUBY_DIR}/mruby"
    end
end

task :build_mruby do
    temp_path = Dir.pwd
    if ANYOLITE_COMPILER == :msvc
        system "cd #{ANYOLITE_MRUBY_DIR}/mruby & ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{ANYOLITE_BUILDPATH}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{ANYOLITE_MRUBY_CONFIG_PATH}\""
    elsif ANYOLITE_COMPILER == :gcc
        system "cd #{ANYOLITE_MRUBY_DIR}/mruby; ruby minirake MRUBY_BUILD_DIR=\"#{temp_path}/#{ANYOLITE_BUILDPATH}/mruby\" MRUBY_CONFIG=\"#{temp_path}/#{ANYOLITE_MRUBY_CONFIG_PATH}\""
    end
end

task :build_glue do
    FileUtils.mkdir_p(ANYOLITE_BUILDPATH + "/glue")

    if ANYOLITE_COMPILER == :msvc
        GLUE_FILES.each do |name|
            system "cl /I #{ANYOLITE_MRUBY_DIR}/mruby/include /D MRB_INT64 /c glue/#{name}.c /Fo\"#{ANYOLITE_BUILDPATH}/glue/#{name}.obj\""
        end
    elsif ANYOLITE_COMPILER == :gcc
        GLUE_FILES.each do |name|
            system "cc -std=c99 -I#{ANYOLITE_MRUBY_DIR}/mruby/include -DMRB_INT64 -c glue/#{name}.c -o #{ANYOLITE_BUILDPATH}/glue/#{name}.o"
        end
    end
end
