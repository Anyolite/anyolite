@echo off
md build
cd build
md glue
cd ..
git clone https://github.com/mruby/mruby --recursive third_party/mruby
cl /I third_party/mruby/include /D MRB_INT64 /c glue/return_functions.c /Fo"build\glue\return_functions.obj"
cl /I third_party/mruby/include /D MRB_INT64 /c glue/data_helper.c /Fo"build\glue\data_helper.obj"
cl /I third_party/mruby/include /D MRB_INT64 /c glue/script_helper.c /Fo"build\glue\script_helper.obj"
cd third_party/mruby
ruby minirake MRUBY_BUILD_DIR="../../build/mruby" MRUBY_CONFIG="../../utility/mruby_build_config.rb"
cd ..
cd ..
