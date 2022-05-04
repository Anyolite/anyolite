require "./Main.cr"

Anyolite::Preloader.transform_script_to_bytecode(ARGV[0], ARGV[1])
