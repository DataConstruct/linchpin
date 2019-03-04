require 'thor'
require 'templater'

class Linchpin < Thor
  desc "build", "attempt to auto-discover application type and build it."
  def build
    app_type = discover_type(Dir.pwd)
    case app_type
    when 'dotnet'
      build_dotnet
    else
      raise "Error: Could not build app type #{app_type}."
    end
  end

  private

  def discover_type(root_dir)
    'dotnet' if Dir["#{root_dir}/*.sln"].any?
  end

  def build_dotnet()
    entry_dir = ''
    Find.find('./') do |path|
      if path =~ /.*Program\.cs$/ and !path.include? 'common' and !path.include? 'obj'
        puts "Found #{path}"
        entry_dir = File.dirname(path)
      end
    end

    entry_dll = ''
    Find.find(entry_dir) do |path|
      if path =~ /.*\.csproj$/
        entry_dll = "#{File.basename(path, ".csproj")}.dll"
      end
    end


    file = Tempfile.new('Dockerfile')
    dockerfile = file.path
    file.write(Templater.new(entry_dll).render)
    file.rewind # => "hello world"
    file.close

    escaped_command = Shellwords.escape("docker build . -f #{dockerfile} -t lol")
    command_output = system({}, "bash -c #{escaped_command}")

    file.unlink
  end
end