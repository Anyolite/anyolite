#include <ruby.h>

//! TODO: Which functions are actually needed and which are not?
//! TODO: Is a cleanup maybe possible? For now, the state is kept.

extern void* open_interpreter(void) {

  static int once = 0;

  if(!once) {

    int argc = 0;
    char** argv = 0;
    ruby_sysinit(&argc, &argv);
    RUBY_INIT_STACK;
    ruby_init();

  }

  once = 1;
  return (void*) 0;

}

extern void close_interpreter(void* mrb) {

  //ruby_cleanup(0);

}

extern void load_script_from_file(void* mrb, const char* filename) {

  ruby_script(filename);

  char* args[2];
  args[0] = "test";
  args[1] = (char*) filename;

  void* options = ruby_options(2, args);

  int return_value = ruby_run_node(options);
  
}