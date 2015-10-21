require 'docker'
require_relative 'compose_port'
require_relative '../utils/compose_utils'

class ComposeEntry
  attr_reader :compose_attributes, :base_image, :container

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

    prepare_image
    prepare_container
  end

  private

  #
  # Download or build an image
  #
  def prepare_image
    has_both = @compose_attributes.key?(:image) && @compose_attributes.key?(:build)
    has_none = !@compose_attributes.key?(:image) && !@compose_attributes.key?(:build)

    if has_both
      raise ArgumentError.new('Docker compose should provide Image OR Build command, not both')
    elsif has_none
      raise ArgumentError.new('No Image or Build command provided')
    end

    # Build or pull image
    if compose_attributes.key?(:image)
      #puts "Pulling image: #{compose_attributes[:image]}"
      base_image = Docker::Image.create('fromImage' => compose_attributes[:image])
    elsif compose_attributes.key?(:build)
      #puts "Building image from: #{compose_attributes[:build]}"
      base_image = Docker::Image.build_from_dir(compose_attributes[:build])
    end
  end

  #
  # Start a new container with parameters informed in object construction
  # (TODO: start container from a Dockerfile)
  #
  def prepare_container
    exposed_ports = {}
    port_bindings = {}

    if !@compose_attributes[:ports].nil?
      @compose_attributes[:ports].each do |port|
        exposed_ports["#{port.container_port}/tcp"] = {}
        port_bindings["#{port.container_port}/tcp"] = [{
          "HostIp" => port.host_ip || '',
          "HostPort" => port.host_port || ''
        }]
      end
    end

    container_config = {
      Image: @compose_attributes[:image],
      Cmd: @compose_attributes[:command],
      Env: @compose_attributes[:environment],
      Volumes: @compose_attributes[:volumes],
      ExposedPorts: exposed_ports,
      HostConfig: {
        #Links: @compose_attributes[:links],
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

  public

  def start
    @container.start unless @container.nil?
  end

  def stop
    @container.kill unless @container.nil?
  end

  def kill
    @container.kill unless @container.nil?
  end

  def delete
    @container.delete(:force => true) unless @container.nil?
    @container = nil
  end
end
