.PHONY: all
all: build/glue/return_functions.o build/glue/data_helper.o build/glue/script_helper.o build/mruby/lib/libmruby.a

build/mruby/lib/libmruby.a:
	mkdir -p build
	git clone https://github.com/mruby/mruby --recursive mruby
	cd third_party/mruby; ruby minirake MRUBY_BUILD_DIR="../../build/mruby" MRUBY_CONFIG="../../utility/mruby_build_config.rb"

build/glue/return_functions.o: glue/return_functions.c | build/mruby/lib/libmruby.a
	mkdir -p build
	mkdir -p build/glue
	$(CC) -std=c99 -Ithird_party/mruby/include -DMRB_INT64 -c $< -o $@

build/glue/data_helper.o: glue/data_helper.c | build/mruby/lib/libmruby.a
	mkdir -p build
	mkdir -p build/glue
	$(CC) -std=c99 -Ithird_party/mruby/include -DMRB_INT64 -c $< -o $@

build/glue/script_helper.o: glue/script_helper.c | build/mruby/lib/libmruby.a
	mkdir -p build
	mkdir -p build/glue
	$(CC) -std=c99 -Ithird_party/mruby/include -DMRB_INT64 -c $< -o $@
