require "./Main.cr"

puts Anyolite::Preloader.transform_script_to_bytecode_array(ARGV[0])
