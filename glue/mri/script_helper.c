#include <ruby.h>

//! TODO: Is a cleanup maybe possible? For now, the state is kept.

extern void* open_interpreter(void) {

  static int already_initialized = 0;

  if(!already_initialized) {

    //printf("Initializing...\n");
    RUBY_INIT_STACK;
    ruby_init();
    //printf("Done initializing.\n");
    already_initialized = 1;

  }

  return (void*) 0;

}

extern void close_interpreter(void* mrb) {

  //printf("Finalizing...\n");
  //ruby_cleanup(0);
  //printf("Done finalizing.\n");

}

extern void load_script_from_file(void* mrb, const char* filename) {

  //printf("Running...\n");
  ruby_script(filename);

  int error;

  char* args[2] = {"test", (char*) filename};

  void* options = ruby_options(2, args);

  int return_value = ruby_run_node(options);
  //printf("Done running.\n");

}