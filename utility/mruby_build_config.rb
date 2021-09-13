MRuby::Build.new do |conf|

  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
    
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
