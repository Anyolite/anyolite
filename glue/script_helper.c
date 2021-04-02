#include <ruby.h>
#include <ruby/class.h>
#include <ruby/data.h>
#include <ruby/compile.h>

extern mrb_value load_script_from_file(mrb_state* mrb, const char* filename) {

    mrbc_context* new_context = mrbc_context_new(mrb);
    mrbc_filename(mrb, new_context, filename);

    FILE* file = fopen(filename, "r");

    if(!file) {

        //! TODO: Error

    }

    int ai = mrb_gc_arena_save(mrb);
    mrb_value status = mrb_load_file_cxt(mrb, file, new_context);
    mrb_gc_arena_restore(mrb, ai);

    if(file) fclose(file);

    if(mrb->exc) mrb_print_error(mrb);

    mrb_free(mrb, new_context);

    return status;

}

extern mrb_value execute_script_line(mrb_state* mrb, const char* str) {

    int ai = mrb_gc_arena_save(mrb);
    mrb_value status = mrb_load_string(mrb, str);
    mrb_gc_arena_restore(mrb, ai);

    return status;
    
}