require_relative 'docker-compose/models/compose'
require_relative 'docker-compose/models/compose_container'
require_relative 'version'

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
  # Load a given docker-compose file.
  # Returns a new Compose object
  #
  def self.load(filepath)
    unless File.exist?(filepath)
      raise ArgumentError, 'Compose file doesn\'t exists'
    end

    compose = Compose.new

    _compose_entries = YAML.load_file(filepath)
    _compose_entries.each do |entry|
      compose.add_container(create_container(entry))
    end

    # Perform containers linkage
    compose.link_containers

    compose
  end

  def self.create_container(attributes)
    ComposeContainer.new({
      label: attributes[0],
      name: attributes[1]['container_name'],
      image: attributes[1]['image'],
      build: attributes[1]['build'],
      links: attributes[1]['links'],
      ports: attributes[1]['ports'],
      volumes: attributes[1]['volumes'],
      command: attributes[1]['command'],
      environment: attributes[1]['environment']
    })
  end

  private_class_method :create_container
end
