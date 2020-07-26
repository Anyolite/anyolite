mkdir -p build
cc -std=c99 -Ithird_party/mruby/include -DMRB_INT64 -c helper.c -o build/helper.o
cd third_party/mruby
ruby minirake MRUBY_BUILD_DIR="../../build/mruby" MRUBY_CONFIG="../../utility/mruby_build_config.rb"