module ContainerUtils
  class << self

    def from_image(image_name)
      Docker::Image.create('fromImage' => image_name) unless image_exists(image_name)
      image_name
    end

    def from_build(build_file)
      name = SecureRandom.hex # Random name for image
      Docker::Image.build_from_dir(build_file, {t: name})
      name
    end

    def create_container(container_props)
      attributes = container_props[:attributes]
      internal_image = container_props[:internal_image]
      port_bindings = container_props[:port_bindings]
      links = container_props[:links]
      volumes = container_props[:volumes]
      volume_binds = container_props[:volume_binds]

      # Exposed ports are port bindings with an empty hash as value
      exposed_ports = {}
      container_props[:port_bindings].each {|k, v| exposed_ports[k] = {}}

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
      Docker::Container.create(params)
    end

    def prepare_port_bindings(ports)
      port_bindings = {}

      return port_bindings if ports.nil?

      ports.each do |port|
        port_bindings["#{port.container_port}/tcp"] = [{
          "HostIp" => port.host_ip || '',
          "HostPort" => port.host_port || ''
        }]
      end

      port_bindings
    end

    def prepare_links(links, dependencies)
      dependencies.map do |dependency|
        link_name = links[dependency.attributes.label]
        "#{dependency.stats['Id']}:#{link_name}"
      end
    end

    def prepare_volumes(raw_volumes)
      return unless raw_volumes

      volumes = {}

      raw_volumes.each do |volume|
        parts = volume.split(':')

        if parts.one?
          volumes[parts[0]] = {}
        else
          volumes[parts[1]] = { parts[0] => parts[2] || 'rw' }
        end
      end

      volumes
    end

  private

    def image_exists(image_name)
      Docker::Image.exist?(image_name)
    end
  end
end
