#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/dump.h>
#include <mruby/proc.h>
#include <mruby/internal.h>

#include <stdlib.h>

extern mrb_value load_script_from_file(mrb_state* mrb, const char* filename) {

    mrbc_context* new_context = mrbc_context_new(mrb);
    mrbc_filename(mrb, new_context, filename);

    FILE* file = fopen(filename, "r");

    if(!file) {

        mrb_raisef(mrb, E_RUNTIME_ERROR, "Could not load script file: %s", filename);

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

        //! TODO: Find out why this does trigger an unstoppable IOT signal
        mrb_raisef(mrb, E_RUNTIME_ERROR, "Could not load bytecode file: %s", filename);

	}

	mrb_value status = mrb_load_irep_file(mrb, file);

	if (file) fclose(file);

    if(mrb->exc) mrb_print_error(mrb);

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

    }

    mrb_value result = mrb_load_file_cxt(mrb, file, new_context);

    if (mrb_undef_p(result)) {

        return 2;

    }

    if(file) fclose(file);

    const mrb_irep *irep = mrb_proc_ptr(result)->body.irep;

    FILE* outfile = fopen(target_filename, "wb");

    if (!outfile) {

        return 3;

    }

    mrb_dump_irep_binary(mrb, irep, 4, outfile);

    if(outfile) fclose(outfile);

    mrb_free(mrb, new_context);

    return 0;

}

typedef struct bytecode_container {

    uint8_t* content;
    size_t size;
    int error_code;
    int result;

} bytecode_container_t;

extern bytecode_container_t transform_script_to_bytecode_container(const char* filename) {

    mrb_state *mrb = mrb_open_core(NULL, NULL);

    mrbc_context* new_context = mrbc_context_new(mrb);
    new_context->no_exec = TRUE;
    mrbc_filename(mrb, new_context, filename);

    bytecode_container_t container = {NULL, 0, 0, 0};

    FILE* file = fopen(filename, "rb");

    if(!file) {

        container.error_code = 1;
        return container;

    }

    mrb_value result = mrb_load_file_cxt(mrb, file, new_context);

    if (mrb_undef_p(result)) {

        container.error_code = 2;
        return container;

    }

    if(file) fclose(file);

    const mrb_irep *irep = mrb_proc_ptr(result)->body.irep;

    uint8_t *bin = NULL;
    size_t bin_size = 0;

    container.result = mrb_dump_irep(mrb, irep, 4, &bin, &bin_size);

    container.content = (uint8_t*) malloc(bin_size * sizeof(uint8_t));
    memcpy(container.content, bin, bin_size);
    container.size = bin_size;

    return container;

}

extern bytecode_container_t transform_proc_to_bytecode_container(mrb_state* mrb, mrb_value proc_object) {

    bytecode_container_t container = {NULL, 0, 0, 0};

    const mrb_irep *irep = mrb_proc_ptr(proc_object)->body.irep;

    uint8_t *bin = NULL;
    size_t bin_size = 0;

    container.result = mrb_dump_irep(mrb, irep, 4, &bin, &bin_size);

    container.content = (uint8_t*) malloc(bin_size * sizeof(uint8_t));
    memcpy(container.content, bin, bin_size);
    container.size = bin_size;

    return container;

}

extern void free_bytecode_container(bytecode_container_t container) {

    free(container.content);

}