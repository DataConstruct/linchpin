require 'erb'

# Provides bindings for a template
module Linchpin
  class Templater
    include ERB::Util

    def initialize(entry_dll)
      @entry_dll = entry_dll
      @template_loc = File.join(File.join(File.dirname(File.expand_path(__FILE__)), 'dockerfiles'),'dotnet-Dockerfile.erb')
    end

    def render
      template = ERB.new File.new(@template_loc).read, nil, '%'
      template.result(binding)
    end
  end
end
