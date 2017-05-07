module V1
  class Container
    attr_reader :image, :definition, :docker_container

    def initialize(definition)
      byebug

      @definition = definition
      #
      # prepare_image
      #
      # @docker_container = DockerClientProxy.instance.create_container(container_props)
    end

    def container_props
      {
        Image: image,
        Cmd: cmd,
        Env: env,
        Labels: labels,
        Volumes: volumes,
        ExposedPorts: exposed_ports,
        HostConfig: {
          Binds: volume_bindings,
          Links: links,
          PortBindings: port_bindings
        }
      }
    end

    def volumes
      volumes_def = definition.volumes

      volumes = {}

      volumes_def.each do |volume|
        parts = volume.split(':')

        if parts.one?
          volumes[parts[0]] = {}
        else
          volumes[parts[1]] = { parts[0] => parts[2] || 'rw' }
        end
      end

      volumes
    end

    def exposed_ports
      Hash[
        port_bindings.map { |k, _| [k, {}] }
      ]
    end

    def volume_bindings
      volumes = definition.volumes
      volumes && volumes.reject { |volume| volume.split(':').one? }
    end

    def links
      dependencies.map do |dependency|
        link_name = definition.links[dependency.label]
        "#{dependency.stats['Id']}:#{link_name}"
      end
    end

    def port_bindings
      ports_def = definition.ports

      Hash[
        ports_def.map do |port|
          [
            "#{port.container_port}/tcp",
            [{
              "HostIp" => port.host_ip || '',
              "HostPort" => port.host_port || ''
            }]
          ]
        end
      ]
    end

    def labels
      labels = definition.labels

      return labels unless labels.is_a?(Array)
      Hash[
        labels.map { |label| label.split('=') }
      ]
    end

    %i(command env).each do |method|
      #
      # TODO: Use delegator
      #
      define_method(method) do
        definition.send(method)
      end
    end

  private

    def prepare_image
      @image =
        case
        when definition.image
          ImageUtils.pull_image(definition.image)
        when definition.build
          ImageUtils.build_image_from_file(definition.build)
        else
          nil
        end
    end
  end
end
