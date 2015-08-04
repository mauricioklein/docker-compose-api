require "docker-compose/version"
require "docker-compose/models/compose_entry"

require 'yaml'
require 'docker'

module DockerCompose
  def self.getDockerClient()
    Docker
  end

  def self.load(filepath)
    unless File.exist?(filepath)
      puts("Compose file doesn't exists")
    end

    @entries = Hash.new
    _compose_entries = YAML.load_file(filepath)
    _compose_entries.each do |entry|
      attr_hash = {
        'label'   => entry[0],
        'build'   => entry[1]['build'],
        'image'   => entry[1]['image'],
        'expose'  => entry[1]['expose'],
        'command' => entry[1]['command']
      }

      composeEntry = ComposeEntry.new(attr_hash)
      composeEntry.prepareImage
      composeEntry.prepareContainer
      @entries[attr_hash['label']] = composeEntry
      #@entries.merge({:attr_hash['label'] => composeEntry})
    end
  end

  def self.containers
    @entries
  end

  def self.startContainers(ids = [])
    if ids.empty?
      ids = @entries.keys
    end

    ids.each do |id|
      if @entries.has_key?(id)
        puts "Starting container: #{id}"
        @entries[id].start
      else
        puts "Container '#{id}' not found!"
      end
    end
  end

  def self.stopContainers(ids = [])
    if ids.empty?
      ids = @entries.keys
    end

    ids.each do |id|
      if @entries.has_key?(id)
        puts "Stoping container: #{id}"
        @entries[id].stop
      else
        puts "Container '#{id}' not found!"
      end
    end
  end
end
