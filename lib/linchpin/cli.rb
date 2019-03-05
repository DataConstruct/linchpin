require 'thor'
require 'linchpin/templater'
require 'shellwords'
require 'find'
require 'tempfile'

class LinchpinCLI < Thor
  desc "build", "attempt to auto-discover application type and build it."
  def build
    app_type = discover_type(Dir.pwd)
    app_name = discover_appname
    case app_type
    when 'dotnet'
      puts "Building dotnet app #{app_name}"
      build_dotnet(app_name, get_version_hash)
    else
      raise "Error: Could not build app type #{app_type}."
    end
  end

  desc "push", "push artifact to repository"
  def push
    app_name = discover_appname
    version = get_version_hash
    escaped_command = Shellwords.escape("docker push dataconstruct/#{app_name}:#{version}")
    command_output = system({}, "bash -c #{escaped_command}")
    exit(1) unless command_output
  end
  private

  def discover_type(root_dir)
    'dotnet' if Dir["#{root_dir}/*.sln"].any?
  end

  def discover_appname
    `git config --get remote.origin.url`.split('/').last.gsub!('.git', '').strip
  end

  def get_version_hash
    `git rev-parse HEAD`.strip
  end

  def build_dotnet(app_name, version)
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
    file.write(Linchpin::Templater.new(entry_dll).render)
    file.rewind # => "hello world"
    file.close

    puts "BUILDING #{app_name}:#{version}"

    escaped_command = Shellwords.escape("docker build . -f #{dockerfile} -t dataconstruct/#{app_name}:#{version}")
    command_output = system({}, "bash -c #{escaped_command}")

    file.unlink

    exit(1) unless command_output
  end
end