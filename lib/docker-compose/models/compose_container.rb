require 'docker'
require 'securerandom'
require_relative 'compose_port'
require_relative '../utils/compose_utils'
require_relative '../utils/container_params'

class ComposeContainer
  attr_reader :attributes, :internal_image, :container, :dependencies

  def initialize(hash_attributes, docker_container = nil)
    @attributes = Container::Params.new(hash_attributes)

    # Docker client variables
    @internal_image = nil
    @container = docker_container
    @dependencies = []
  end

  #
  # Returns true if is a container loaded from
  # environment instead compose file (i.e. a running container)
  #
  def loaded_from_environment?
    attributes.loaded_from_environment?
  end

  #
  # Start the container and its dependencies
  #
  def start
    # Start dependencies
    dependencies.each do |dependency|
      dependency.start unless dependency.running?
    end

    # Create a container object
    if container.nil?
      prepare_image
      prepare_container
    end

    container.start unless container.nil?
  end

  #
  # Stop the container
  #
  def stop
    container.stop unless container.nil?
  end

  #
  # Kill the container
  #
  def kill
    container.kill unless container.nil?
  end

  #
  # Delete the container
  #
  def delete
    container.delete(force: true) unless container.nil?
    container = nil
  end

  #
  # Add a dependency to this container
  # (i.e. a container that must be started before this one)
  #
  def add_dependency(dependency)
    @dependencies << dependency
  end

  #
  # Return container statistics
  #
  def stats
    container.json
  end

  #
  # Check if a container is already running or not
  #
  def running?
    container.nil? ? false : self.stats['State']['Running']
  end

  #
  # Check if the container exists or not
  #
  def exist?
    container.present?
  end

  private

  #
  # Download or build an image
  #
  def prepare_image
    has_image_or_build_arg = attributes.image || attributes.build

    raise ArgumentError.new('No Image or Build command provided') unless has_image_or_build_arg

    # Build or pull image
    if attributes.image
      @internal_image = attributes.image

      unless image_exists(internal_image)
        Docker::Image.create('fromImage' => internal_image)
      end
    elsif attributes.build
      @internal_image = SecureRandom.hex # Random name for image
      Docker::Image.build_from_dir(attributes.build, {t: internal_image})
    end
  end

  #
  # Start a new container with parameters informed in object construction
  #
  def prepare_container
    # Prepare attributes
    port_bindings = prepare_port_bindings
    links = prepare_links
    volumes = prepare_volumes
    volume_binds = attributes.volumes && attributes.volumes.reject { |volume| volume.split(':').one? }

    # Exposed ports are port bindings with an empty hash as value
    exposed_ports = {}
    port_bindings.each {|k, v| exposed_ports[k] = {}}

    container_config = {
      Image: internal_image,
      Cmd: attributes.command,
      Env: attributes.environment,
      Volumes: volumes,
      ExposedPorts: exposed_ports,
      Labels: attributes.labels,
      HostConfig: {
        Binds: volume_binds,
        Links: links,
        PortBindings: port_bindings
      }
    }

    query_params = { 'name' => attributes.name }

    params = container_config.merge(query_params)
    @container = Docker::Container.create(params)
  end

  #
  # Prepare port binding attribute based on ports
  # received from compose file
  #
  def prepare_port_bindings
    port_bindings = {}

    return port_bindings if attributes.ports.nil?

    attributes.ports.each do |port|
      port_bindings["#{port.container_port}/tcp"] = [{
        "HostIp" => port.host_ip || '',
        "HostPort" => port.host_port || ''
      }]
    end

    port_bindings
  end

  #
  # Prepare link entries based on
  # attributes received from compose
  #
  def prepare_links
    links = []

    dependencies.each do |dependency|
      link_name = attributes.links[dependency.attributes.label]
      links << "#{dependency.stats['Id']}:#{link_name}"
    end

    links
  end

  #
  # Transforms an array of [(host:)container(:accessmode)] to a hash
  # required by the Docker api.
  #
  def prepare_volumes
    return unless attributes.volumes

    volumes = {}

    attributes.volumes.each do |volume|
      parts = volume.split(':')

      if parts.one?
        volumes[parts[0]] = {}
      else
        volumes[parts[1]] = { parts[0] => parts[2] || 'rw' }
      end
    end

    volumes
  end

  #
  # Check if a given image already exists in host
  #
  def image_exists(image_name)
    Docker::Image.exist?(image_name)
  end
end
