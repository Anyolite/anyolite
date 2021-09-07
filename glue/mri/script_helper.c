#include <ruby.h>

extern void* open_interpreter(void) {

  static int first_run = 1;

  if(!first_run) {

    printf("ERROR: Only one Ruby interpreter can be used at this point.\n");
    return (void*) 0;

  }

  RUBY_INIT_STACK;
  ruby_init();

  first_run = 0;

  return (void*) 0;

}

extern void close_interpreter(void* rb) {

  static int first_run = 1;

  if(!first_run) {

    return;

  }

  first_run = 0;

  ruby_cleanup(0);

}

extern void load_script_from_file(void* rb, const char* filename) {

  static int first_run = 1;

  char* args[2] = {"test", (char*) filename};
  
  if(!first_run) {

    printf("ERROR: Ruby scripts can only be run once at this point.\n");
    return;

  }

  void* options = ruby_options(2, args);

  int ex_node_status;
  int ex_node_return = ruby_executable_node(options, &ex_node_status);

  if(!ex_node_return) {

    printf("Error: File %s could not be executed.\n", filename);
    ruby_cleanup(ex_node_status);
    return;

  }

  int return_value = ruby_exec_node(options);

  VALUE exception = rb_errinfo();
  if(exception != Qnil) {

    VALUE exception_str = rb_inspect(exception);

    printf("%s\n", rb_string_value_cstr(&exception_str));

  }

  first_run = 0;

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