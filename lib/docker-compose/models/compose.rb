require 'docker'
require_relative 'compose_port'
require_relative '../utils/compose_utils'

class Compose
  attr_reader :containers

  def initialize
    @containers = {}
  end

  public

  #
  # Add a new container to compose
  #
  def add_container(container)
    @containers[container.attributes[:label]] = container
    true
  end

  #
  # Create link relations among containers
  #
  def link_containers
    @containers.each_value do |container|
      links = container.attributes[:links]

      next if links.nil?

      links.each do |link|
        dependency_container = @containers[link]
        container.dependencies << dependency_container
      end
    end
  end

  #
  # Start a container
  #
  # This method accepts an array of labels.
  # If labels is informed, only those containers with label present in array will be started.
  # Otherwise, all containers are started
  #
  def start(labels = [])
    call_container_method(:start, labels)
  end

  #
  # Stop a container
  #
  # This method accepts an array of labels.
  # If labels is informed, only those containers with label present in array will be stopped.
  # Otherwise, all containers are stopped
  #
  def stop(labels = [])
    call_container_method(:stop, labels)
  end

  #
  # Stop a container
  #
  # This method accepts an array of labels.
  # If labels is informed, only those containers with label present in array will be stopped.
  # Otherwise, all containers are stopped
  #
  def kill(labels  = [])
    call_container_method(:kill, labels)
  end

  private

  def call_container_method(method, labels = [])
    labels = @containers.keys if labels.empty?

    containers = @containers.select { |key, value|
      labels.include?(key)
    }

    containers.values.each do |entry|
      entry.send(method)
    end

    true
  end
end
