MRuby::Build.new do |conf|

  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp

     # The definition for ssize_t is due to a compilation error from mruby on Windows, where ssize_t is apparently not defined
     # If this gets fixed, the following line can be removed safely
    conf.cc.flags << '-Dssize_t=int'
    
    conf.yacc do |yacc|
      yacc.command = ENV['YACC'] || 'bison.exe'
      yacc.compile_options = %q[-o "%{outfile}" "%{infile}"]
    end
  else
    toolchain :gcc
  end

  conf.gembox 'default'

  conf.gem :mgem => 'json'
  conf.gem :mgem => 'dir'
  conf.gem :mgem => 'regexp-pcre'

  conf.cc.flags << '-DMRB_UTF8_STRING -DMRB_INT64'

  conf.build_dir = ENV["MRUBY_BUILD_DIR"] || raise("MRUBY_BUILD_DIR undefined!")

end
