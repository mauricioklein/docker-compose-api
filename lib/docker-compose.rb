require 'docker-compose/version'
require 'docker-compose/models/compose_entry'

require 'yaml'
require 'docker'

module DockerCompose
  #
  # Get Docker client object
  #
  def self.docker_client
    Docker
  end

  #
  # Load a given docker-compose file
  #
  def self.load(filepath)
    unless File.exist?(filepath)
      puts("Compose file doesn't exists")
      raise ENOENT
    end

    @entries = {}

    _compose_entries = YAML.load_file(filepath)
    _compose_entries.each do |entry|
      attr_hash = {
        label: entry[0],
        image: entry[1]['image'],
        build: entry[1]['build'],
        links: entry[1]['links'],
        ports: entry[1]['ports'],
        volumes: entry[1]['volumes'],
        command: entry[1]['command'],
        environment: entry[1]['environment']
      }

      composeEntry = ComposeEntry.new(attr_hash)
      @entries[attr_hash[:label]] = composeEntry
    end
  end

  #
  # Returns compose entries
  #
  # If a container label is given, returns the container represented by this label.
  # Otherwise, returns all containers
  #
  def self.entries(label = nil)
    if label.nil?
      @entries.values
    else
      @entries[label]
    end
  end

  #
  # Start a container
  #
  # This method accepts an array of labels.
  # If labels is informed, only those containers with label present in array will be started.
  # Otherwise, all containers are started
  #
  def self.start(labels = [])
    self.call_container_method(:start, labels)
  end

  #
  # Stop a container
  #
  # This method accepts an array of labels.
  # If labels is informed, only those containers with label present in array will be stopped.
  # Otherwise, all containers are stopped
  #
  def self.stop(labels = [])
    self.call_container_method(:stop, labels)
  end

  #
  # Stop a container
  #
  # This method accepts an array of labels.
  # If labels is informed, only those containers with label present in array will be stopped.
  # Otherwise, all containers are stopped
  #
  def self.kill(labels  = [])
    self.call_container_method(:kill, labels)
  end

  private_class_method
  def self.call_container_method(method, labels = [])
    if labels.empty?
      labels = @entries.keys
    end

    entries = @entries.select { |key, value|
      labels.include?(key)
    }

    entries.values.each do |entry|
      entry.send(method)
    end
  end
end
