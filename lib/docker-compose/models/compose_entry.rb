require 'docker'
require_relative 'compose_port'
require_relative '../utils/compose_utils'

class ComposeEntry
  attr_reader :compose_attributes, :base_image, :container, :dependencies

  def initialize(hash_attributes)
    @compose_attributes = {
      label: hash_attributes[:label],
      image: ComposeUtils.format_image(hash_attributes[:image]),
      build: hash_attributes[:build],
      links: hash_attributes[:links],
      ports: prepare_ports(hash_attributes[:ports]),
      #expose: hash_attributes[:expose],
      volumes: hash_attributes[:volumes],
      command: ComposeUtils.format_command(hash_attributes[:command]),
      environment: hash_attributes[:environment]
    }.reject{ |key, value| value.nil? }

    # Docker client variables
    @base_image = nil
    @container = nil
    @dependencies = []
  end

  private

  #
  # Download or build an image
  #
  def prepare_image
    has_image_or_build_arg = @compose_attributes.key?(:image) || @compose_attributes.key?(:build)

    raise ArgumentError.new('No Image or Build command provided') unless has_image_or_build_arg

    # Build or pull image
    if @compose_attributes.key?(:image)
      if image_exists
        base_image = Docker::Image.get(@compose_attributes[:image])
      else
        base_image = Docker::Image.create('fromImage' => @compose_attributes[:image])
      end
    elsif @compose_attributes.key?(:build)
      base_image = Docker::Image.build_from_dir(@compose_attributes[:build])
    end
  end

  #
  # Start a new container with parameters informed in object construction
  # (TODO: start container from a Dockerfile)
  #
  def prepare_container
    exposed_ports = {}
    port_bindings = {}
    links = []

    # Build expose and port binding parameters
    if !@compose_attributes[:ports].nil?
      @compose_attributes[:ports].each do |port|
        exposed_ports["#{port.container_port}/tcp"] = {}
        port_bindings["#{port.container_port}/tcp"] = [{
          "HostIp" => port.host_ip || '',
          "HostPort" => port.host_port || ''
        }]
      end
    end

    # Build link parameters
    @dependencies.each do |dependency|
      links << dependency.container.json['Id']
    end

    container_config = {
      Image: @compose_attributes[:image],
      Cmd: @compose_attributes[:command],
      Env: @compose_attributes[:environment],
      Volumes: @compose_attributes[:volumes],
      ExposedPorts: exposed_ports,
      HostConfig: {
        Links: links,
        PortBindings: port_bindings
      }
    }

    @container = Docker::Container.create(container_config)
  end

  #
  # Process each port entry in docker compose file and
  # create structure recognized by docker client
  #
  def prepare_ports(port_entries)
    ports = []

    if port_entries.nil?
      return nil
    end

    port_entries.each do |port_entry|
      ports.push(ComposeUtils.format_port(port_entry))
    end

    ports
  end

  #
  # Check if a given image already exists in host
  #
  def image_exists
    Docker::Image.exist?(@compose_attributes[:image])
  end

  public

  #
  # Start the container and its dependencies
  #
  def start
    # Start dependencies
    @dependencies.each do |dependency|
      dependency.start unless dependency.is_running?
    end

    # Create a container object
    if @container.nil?
      prepare_image
      prepare_container
    end

    @container.start unless @container.nil?
  end

  #
  # Stop the container
  #
  def stop
    @container.kill unless @container.nil?
  end

  #
  # Kill the container
  #
  def kill
    @container.kill unless @container.nil?
  end

  #
  # Delete the container
  #
  def delete
    @container.delete(:force => true) unless @container.nil?
    @container = nil
  end

  #
  # Add a dependency to this container
  # (i.e. a container that must be started before this one)
  #
  def add_dependency(dependency)
    @dependencies << dependency
  end

  #
  # Check if a container is already running or not
  #
  def is_running?
    @container.nil? ? false : @container.json['State']['Running']
  end
end
