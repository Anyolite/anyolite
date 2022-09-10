MRuby::Build.new do |conf|

  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
    conf.cc.flags = "/nologo /W3 /MT /O2 /D_CRT_SECURE_NO_WARNINGS"
  else
    toolchain :gcc
  end

  conf.gembox 'default'

  conf.gem :mgem => 'json'
  conf.gem :mgem => 'dir'

  conf.cc.flags << '-DMRB_UTF8_STRING -DMRB_INT64'

  conf.build_dir = ENV["MRUBY_BUILD_DIR"] || raise("MRUBY_BUILD_DIR undefined!")

end
