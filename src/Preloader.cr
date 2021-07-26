module Anyolite
  module Preloader
    @@content = {} of String => Array(UInt8)

    module AtCompiletime
      # Caches the bytecode from *filename*, so it is automatically included 
      # into the final application.
      macro load_bytecode_file(filename)
        {% file_content = read_file?(filename) %}
        {% if file_content %}
          Anyolite::Preloader.add_content({{filename}}, {{file_content}}.bytes)
        {% else %}
          puts "Could not find #{filename}"
        {% end %}
      end

      # Converts the Ruby script in *filename* to bytecode, which is
      # then stored in *target_filename*.
      macro transform_script_to_bytecode(filename, target_filename)
        {% run("./BytecodeCompiler.cr", filename, target_filename) %}
      end
    end

    # Caches the bytecode file *filename*
    def self.add_content(filename : String, bytes : Array(UInt8))
      @@content[filename] = bytes
    end

    # Executes the bytecode file *filename* in context of the `RbInterpreter` *rb*.
    #
    # If it was already cached, it will be taken from the cache instead.
    def self.execute_bytecode_from_cache_or_file(rb : RbInterpreter, filename : String)
      if @@content[filename]?
        rb.execute_bytecode(@@content[filename])
      else
        rb.load_bytecode_from_file(filename)
      end
    end

    # Converts the Ruby script in *filename* to bytecode, which is
    # then stored in *target_filename*.
    def self.transform_script_to_bytecode(filename : String, target_filename : String)
      error_code = RbCore.transform_script_to_bytecode(filename, target_filename)
      case error_code
        when 1 then raise "Could not load script file #{filename}"
        when 2 then raise "Error when loading script file #{filename}"
        when 3 then raise "Could not write to target file #{target_filename}"
      end
    end
  end
end