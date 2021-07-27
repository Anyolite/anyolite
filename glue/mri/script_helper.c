#include "ruby.h"

extern void* open_interpreter(void) {
  RUBY_INIT_STACK;
  ruby_init();
  return (void*) 0;
}