require 'thor'
require 'linchpin/templater'
require 'shellwords'
require 'find'
require 'tempfile'
require 'tmpdir'
require 'fileutils'

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


  desc "deploy", "deploy the application"
  def deploy
    app_name = discover_appname
    short_app_name = discover_short_appname
    app_type = discover_type(Dir.pwd)
    version = get_version_hash

    temp_dir = Dir.mktmpdir
    command_output = false
    begin
      deploy_templates = Dir[File.join(File.join(File.join(File.dirname(File.expand_path(__FILE__)), 'k8s'), app_type),"*.erb")]
      deploy_templates.each do |filename|
        "LOL #{filename}"
        FileUtils.cp(filename, "#{temp_dir}")
      end
      FileUtils.cp(File.join(File.join(File.join(Dir.pwd, 'config'), "deploy"), "secrets.ejson"), "#{temp_dir}")

      escaped_command = Shellwords.escape("KUBECONFIG=~/.kube/config REVISION=#{version} kubernetes-deploy #{short_app_name} cicd-example --template-dir=#{temp_dir} --bindings=full_name=#{app_name},app_name=#{short_app_name}")
      command_output = system({}, "bash -c #{escaped_command}")

    ensure
      # remove the directory.
      FileUtils.remove_entry temp_dir
    end

    exit(1) unless command_output
  end
  private

  def discover_type(root_dir)
    'dotnet' if Dir["#{root_dir}/*.sln"].any?
  end

  def discover_short_appname
    `git config --get remote.origin.url`.split('/').last.gsub!('.git', '').gsub!('sdlc-example-app-', '').strip
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
      if ( path =~ /.*Program\.cs$/ and !path.include? 'common' and !path.include? 'obj' and ( path.include? 'API' or path.include? 'WebMVC' )
        puts "Found #{path}"
        entry_dir = File.dirname(path)
      end
    end

    entry_project = ''
    Find.find(entry_dir) do |path|
      if path =~ /.*\.csproj$/
        entry_project = File.basename(path, ".csproj")
      end
    end


    file = Tempfile.new('Dockerfile')
    dockerfile = file.path
    file.write(Linchpin::Templater.new(entry_project).render)
    file.rewind # => "hello world"
    file.close

    puts "BUILDING #{app_name}:#{version}"

    escaped_command = Shellwords.escape("docker build . -f #{dockerfile} -t dataconstruct/#{app_name}:#{version}")
    command_output = system({}, "bash -c #{escaped_command}")

    file.unlink

    exit(1) unless command_output
  end
end