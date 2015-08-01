require 'yaml'

module DockerCompose::Parser
  def self.load(filepath)
    unless File.exist?(filepath)
      puts "Compose file doesn't exists"
    end

    _compose_entries = YAML.load_file(filepath)
    puts "Compose content: #{_compose_entries.inspect}"
  end
end
