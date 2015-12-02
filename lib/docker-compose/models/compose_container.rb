require 'docker'
require 'securerandom'
require_relative 'compose_port'
require_relative '../utils/compose_utils'

class ComposeContainer
  attr_reader :attributes, :container, :dependencies

  def initialize(hash_attributes)
    @attributes = {
      label: hash_attributes[:label],
      image: ComposeUtils.format_image(hash_attributes[:image]),
      build: hash_attributes[:build],
      links: ComposeUtils.format_links(hash_attributes[:links]),
      ports: prepare_ports(hash_attributes[:ports]),
      volumes: hash_attributes[:volumes],
      command: ComposeUtils.format_command(hash_attributes[:command]),
      environment: prepare_environment(hash_attributes[:environment])
    }.reject{ |key, value| value.nil? }

    # Docker client variables
    @internal_image = nil
    @container = nil
    @dependencies = []
  end

  private

  #
  # Download or build an image
  #
  def prepare_image
    has_image_or_build_arg = @attributes.key?(:image) || @attributes.key?(:build)

    raise ArgumentError.new('No Image or Build command provided') unless has_image_or_build_arg

    # Build or pull image
    if @attributes.key?(:image)
      @internal_image = @attributes[:image]

      unless image_exists(@internal_image)
        Docker::Image.create('fromImage' => @internal_image)
      end
    elsif @attributes.key?(:build)
      @internal_image = SecureRandom.hex # Random name for image
      Docker::Image.build_from_dir(@attributes[:build], {t: @internal_image})
    end
  end

  #
  # Start a new container with parameters informed in object construction
  #
  def prepare_container
    # Prepare attributes
    port_bindings = prepare_port_bindings
    links = prepare_links

    # Exposed ports are port bindings with an empty hash as value
    exposed_ports = {}
    port_bindings.each {|k, v| exposed_ports[k] = {}}

    container_config = {
      Image: @internal_image,
      Cmd: @attributes[:command],
      Env: @attributes[:environment],
      Volumes: @attributes[:volumes],
      ExposedPorts: exposed_ports,
      HostConfig: {
        Links: links,
        PortBindings: port_bindings
      }
    }

    @container = Docker::Container.create(container_config)
  end

  #
  # Prepare port binding attribute based on ports
  # received from compose file
  #
  def prepare_port_bindings
    port_bindings = {}

    return port_bindings if @attributes[:ports].nil?

    @attributes[:ports].each do |port|
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

    @dependencies.each do |dependency|
      links << "#{dependency.stats['Id']}:#{dependency.attributes[:label]}"
    end

    links
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
  # Forces the environment structure to use the array format.
  #
  def prepare_environment(env_entries)
    return env_entries unless env_entries.is_a?(Hash)
    env_entries.to_a.map { |x| x.join('=') }
  end

  #
  # Check if a given image already exists in host
  #
  def image_exists(image_name)
    Docker::Image.exist?(image_name)
  end

  public

  #
  # Start the container and its dependencies
  #
  def start
    # Start dependencies
    @dependencies.each do |dependency|
      dependency.start unless dependency.running?
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
  # Return container statistics
  #
  def stats
    @container.json
  end

  #
  # Check if a container is already running or not
  #
  def running?
    @container.nil? ? false : self.stats['State']['Running']
  end
end
