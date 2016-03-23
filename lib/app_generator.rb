require 'fileutils'

module Moto
  class AppGenerator

    # Creates directories and file with class template for a test.
    # @param options [Hash] Informations required perfrom the task.
    #   options[:app_name]        Name of the application that uses Moto Framework.
    #   options[:dir]             Subdirectories of MotoApp/tests/ where test should be placed.
    #   options[:base_class]      Path and filename of class from which the test will derive.
    #   options[:force]           Whether generator should forcibly overwrite previously existing file.
    def self.run(options)

      # Build list of modules basing on the name of the application and subdirectory provided by the user.
      # Second module is always 'tests' since it's where they should be kept.
      modules = [options[:app_name], 'tests'] + options[:dir].split('/')
      modules.map!(&:camelize)

      # Name of the class in the template
      class_name = modules.last

      # Evaluate fully qualified name of the class to derive from or, if not specified
      # use Moto's default one
      if options[:base_class].nil?
        base_class_qualified_name = 'Moto::Test::Base'
      else
        base_class_qualified_name = "#{options[:app_name]}::Lib::Test::#{options[:base_class].split('/').join('::').camelize}"
      end

      # Where to put finished template
      test_file = File.basename(options[:dir]) + '.rb'
      test_dir = MotoApp::DIR + '/tests/' + options[:dir]
      test_path = "#{test_dir}/#{test_file}"

      # Create directory
      FileUtils.mkdir_p(test_dir)

      if !File.exist?(test_path) || options[:force]
        # Create new file in specified location and add class' template to it
        File.open(test_path, 'w+') do |file|

          indent = 0

          file << "# FULL_CODE\n"

          if options[:base_class].nil?
            file << "\n"
          else
            file << "require './lib/test/#{options[:base_class]}.rb'\n\n"
          end

          modules.each do |m|
            file << (' ' * indent) + "module #{m}\n"
            indent += 2
          end

          file << (' ' * indent) + "# Class template genereated by 'moto generate'\n"
          file << (' ' * indent) + "class #{class_name} < #{base_class_qualified_name}\n\n"
          indent += 2
          file << (' ' * indent) + "def run\n"
          file << (' ' * indent) + "end\n\n"
          indent -= 2
          file << (' ' * indent) + "end\n"

          modules.each do
            indent -= 2
            file << (' ' * indent) + "end\n"
          end

        end

        puts 'Result:'
        puts "  File: #{test_path}"
        puts "  Class: #{class_name} < #{base_class_qualified_name}"
      else
        raise 'File already exists. Use -f or --force to overwrite existing contents.'
      end
    end
  end
end
