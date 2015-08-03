require 'yaml'
require 'docker'

module DockerCompose::Parser
  def self.getDockerClient()
    Docker
  end

  def self.load(filepath)
    unless File.exist?(filepath)
      puts "Compose file doesn't exists"
    end

    @entries = Hash.new
    _compose_entries = YAML.load_file(filepath)
    puts "PLAIN: #{_compose_entries}"
    _compose_entries.each do |entry|
      attr_hash = {
        'id'      => entry[0],
        'build'   => entry[1]['build'],
        'image'   => entry[1]['image'],
        'ports'   => entry[1]['ports'],
        'volumes' => entry[1]['volumes'],
        'links'   => entry[1]['links'],
        'command' => entry[1]['command']
      }
      puts "Entry: #{attr_hash.inspect}"
      @entries[attr_hash['id']] = ComposeEntry.new(attr_hash)
    end
  end

  def self.start
    @entries.each do |id, entry|
      puts "Starting container: #{id}"
      entry.start
    end
  end

  def self.stop
    @entries.each do |id, entry|
      puts "Stoping container: #{id}"
      entry.stop
    end
  end
end
