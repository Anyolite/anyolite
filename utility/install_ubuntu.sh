mkdir -p build
mkdir -p build/glue
cc -std=c99 -Ithird_party/mruby/include -DMRB_INT64 -c glue/return_functions.c -o build/glue/return_functions.o
cc -std=c99 -Ithird_party/mruby/include -DMRB_INT64 -c glue/data_helper.c -o build/glue/data_helper.o
cd third_party/mruby
ruby minirake MRUBY_BUILD_DIR="../../build/mruby" MRUBY_CONFIG="../../utility/mruby_build_config.rb"