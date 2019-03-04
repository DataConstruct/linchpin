require 'erb'

# Provides bindings for a template
class Templater
  include ERB::Util

  def initialize(entry_dll)
    @some_var = entry_dll
    @template_loc = File.join(File.join(File.dirname(File.expand_path(__FILE__)), 'dockerfiles'),'JavaDockerfile.erb')
  end

  def render
    template = ERB.new File.new(@template_loc).read, nil, '%'
    template.result(binding)
  end
end
