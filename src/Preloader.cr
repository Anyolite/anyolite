module Anyolite
  module Preloader
    @@content = {} of String => Array(UInt8)

    module AtCompiletime 
      macro load_bytecode_file(filename)
        {% file_content = read_file?(filename) %}
        {% if file_content %}
          Anyolite::Preloader.add_content({{filename}}, {{file_content}}.bytes)
        {% else %}
          puts "Could not find #{filename}"
        {% end %}
      end

      macro transform_script_to_bytecode(filename, target_filename)
        {% run("./BytecodeCompiler.cr", filename, target_filename) %}
      end
    end

    def self.add_content(filename : String, bytes : Array(UInt8))
      @@content[filename] = bytes
    end

    def self.execute_content(rb : RbInterpreter, filename : String)
      if @@content[filename]?
        rb.execute_bytecode(@@content[filename])
      else
        rb.load_bytecode_from_file(filename)
      end
    end

    def self.transform_script_to_bytecode(filename : String, target_filename : String)
      RbCore.transform_script_to_bytecode(filename, target_filename)
    end
  end
end