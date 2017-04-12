require 'docker'
require 'securerandom'
require_relative 'compose_port'
require_relative '../utils/compose_utils'
require_relative '../utils/container_utils'
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

  def loaded_from_environment?
    attributes.loaded_from_environment?
  end

  def start
    dependencies.each do |dependency|
      dependency.start unless dependency.running?
    end

    unless exist?
      prepare_image
      prepare_container
    end

    container.start if exist?
  end

  def stop
    container.stop if exist?
  end

  def kill
    container.kill if exist?
  end

  def delete
    container.delete(force: true) if exist?
    container = nil
  end

  def add_dependency(dependency)
    @dependencies << dependency
  end

  def stats
    container.json
  end

  def running?
    exist? ? self.stats['State']['Running'] : false
  end

  def exist?
    !container.nil?
  end

private

  def prepare_image
    if attributes.image
      @internal_image = ContainerUtils.from_image(attributes.image)
    elsif attributes.build
      @internal_image = ContainerUtils.from_build(attributes.build)
    else
      raise ArgumentError.new('No Image or Build command provided')
    end
  end

  def prepare_container
    volume_binds = attributes.volumes && attributes.volumes.reject { |volume| volume.split(':').one? }

    @container = ContainerUtils.create_container(
      attributes: attributes,
      internal_image: internal_image,
      port_bindings: ContainerUtils.prepare_port_bindings(attributes.ports),
      links: ContainerUtils.prepare_links(attributes.links, dependencies),
      volumes: ContainerUtils.prepare_volumes(attributes.volumes),
      volume_binds: volume_binds
    )
  end
end
