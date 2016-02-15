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
  def self.load(filepath, do_load_running_containers = false)
    unless File.exist?(filepath)
      raise ArgumentError, 'Compose file doesn\'t exists'
    end

    compose = Compose.new

    # Create containers from compose file
    _compose_entries = YAML.load_file(filepath)

    if _compose_entries
      _compose_entries.each do |entry|
        compose.add_container(create_container(entry))
      end
    end

    # Load running containers
    if do_load_running_containers
      Docker::Container
        .all(all: true)
        .select {|c| c.info['Names'].last.match(/\A\/#{ComposeUtils.dir_name}\w*/) }
        .each do |container|
          compose.add_container(load_running_container(container))
      end
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
      environment: attributes[1]['environment'],
      labels: attributes[1]['labels']
    })
  end

  def self.load_running_container(container)
    info = container.json

    container_args = {
      label:       info['Name'].split(/_/)[1] || '',
      full_name:   info['Name'],
      image:       info['Image'],
      build:       nil,
      links:       info['HostConfig']['Links'],
      ports:       ComposeUtils.format_ports_from_running_container(info['NetworkSettings']['Ports']),
      volumes:     info['Config']['Volumes'],
      command:     info['Config']['Cmd'].join(' '),
      environment: info['Config']['Env'],
      labels:      info['Config']['Labels']
    }

    ComposeContainer.new(container_args, container)
  end

  private_class_method :create_container, :load_running_container
end
