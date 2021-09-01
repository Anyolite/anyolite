#include <ruby.h>

//! TODO: Is a complete cleanup maybe possible? For now, the state is kept.

extern void* open_interpreter(void) {

  RUBY_INIT_STACK;
  ruby_init();

  return (void*) 0;

}

extern void close_interpreter(void* rb) {

  ruby_cleanup(0);

}

extern void load_script_from_file(void* rb, const char* filename) {

  static int first_script = 1;

  if(first_script) {

    ruby_script(filename);
    first_script = 0;

  }

  int error;

  char* args[2] = {"test", (char*) filename};

  void* options = ruby_options(2, args);

  int return_value = ruby_exec_node(options);

  VALUE exception = rb_errinfo();
  if(exception != Qnil) {

    VALUE exception_str = rb_inspect(exception);

    printf("%s\n", rb_string_value_cstr(&exception_str));

  }

  //! TODO: Fix segfaults at second execution

}

extern void execute_script_line(void* rb, const char* text) {

  int status;
  rb_eval_string_protect(text, &status);

  if(status) {

    VALUE exception = rb_errinfo();
    VALUE exception_str = rb_inspect(exception);

    //! TODO: Are there any internal methods to print this prettier?

    printf("%s\n", rb_string_value_cstr(&exception_str));

  }

}