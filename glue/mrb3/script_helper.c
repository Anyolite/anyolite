#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/dump.h>
#include <mruby/proc.h>

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

extern mrb_value load_bytecode_from_file(mrb_state* mrb, const char* filename) {

    FILE* file = fopen(filename, "r");

	if (!file) {

        //! TODO: Error

	}

	mrb_value status = mrb_load_irep_file(mrb, file);

	if (file) fclose(file);

    return status;

}

extern mrb_value execute_bytecode(mrb_state* mrb, const uint8_t* bytecode) {

    int ai = mrb_gc_arena_save(mrb);
    mrb_value status = mrb_load_irep(mrb, bytecode);
    mrb_gc_arena_restore(mrb, ai);

    return status;

}

extern int transform_script_to_bytecode(const char* filename, const char* target_filename) {

    mrb_state *mrb = mrb_open_core(NULL, NULL);

    mrbc_context* new_context = mrbc_context_new(mrb);
    new_context->no_exec = TRUE;
    mrbc_filename(mrb, new_context, filename);

    FILE* file = fopen(filename, "rb");

    if(!file) {

        return 1;
        //! TODO: Error

    }

    mrb_value result = mrb_load_file_cxt(mrb, file, new_context);

    if (mrb_undef_p(result)) {

        return 1;
        //! TODO: Error

    }

    if(file) fclose(file);

    const mrb_irep *irep = mrb_proc_ptr(result)->body.irep;

    FILE* outfile = fopen(target_filename, "wb");

    if (!outfile) {

        return 1;
        //! TODO: Error

    }

    mrb_dump_irep_binary(mrb, irep, 4, outfile);

    if(outfile) fclose(outfile);

    mrb_free(mrb, new_context);

    return 0;

}