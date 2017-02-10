module ComposeUtils
  class << self
    #
    # Returns the directory name where compose
    # file is saved (used in container naming)
    #
    def dir_name
      File.split(Dir.pwd).last.gsub(/[-_]/, '')
    end

    #
    # Provides the next available ID
    # to container names
    #
    def next_available_container_id
      get_container_id = -> (container) { container.info['Names'].last.split(/_/).last.to_i }
      current_container_id = Docker::Container.all(all: true).map { |c| get_container_id(c) }.flatten.max || 0
      current_container_id + 1
    end

    #
    # Format a given docker image in a complete structure (base image + tag)
    #
    def format_image(image)
      return nil if image.nil?
      image.include?(?:) ? image : "#{image}:latest"
    end

    #
    # Transform docker command from string to an array of commands
    #
    def format_command(command)
      command && command.split(' ')
    end

    #
    # Read a port specification in string format
    # and create a compose port structure
    #
    def format_port(port_entry)
      port_parts = port_entry.split(':').reverse

      case port_parts.length
        # [container port]
        when 1
          ComposePort.new(container_port: port_parts[0])

        # [host port]:[container port]
        when 2
          ComposePort.new(container_port: port_parts[0], host_port: port_parts[1])

        # [host ip]:[host port]:[container port]
        when 3
          ComposePort.new(container_port: port_parts[0], host_port: port_parts[1], host_ip: port_parts[2])
      end
    end

    #
    # Format ports from running container
    #
    def format_ports_from_running_container(port_entry)
      return [] if port_entry.nil?

      # e.g. "8000/tcp" => "8000"
      remove_protocol_from_container_port = -> (container_port) { container_port.gsub(/\D/, '').to_i }

      port_entry.map do |container_port, host_mapping|
        host_ip, host_port = '', ''
        container_port = remove_protocol_from_container_port.call(container_port)

        # Ports that are exposed but not published won't have a Host IP/Port,
        # only a Container Port
        unless host_mapping.nil?
          host_ip   = host_mapping.first['HostIp']
          host_port = host_mapping.first['HostPort']
        end

        "#{container_port}:#{host_ip}:#{host_port}"
      end
    end

    #
    # Generate a pair key:hash with
    # format {service:label}
    #
    # The label will be the conainer name if not specified.
    #
    def format_links(links_array)
      return nil if links_array.nil?

      Hash[
        links_array.map do |link|
          service, label = link.split(':')
          [service, label || service]
        end
      ]
    end

    #
    # Generate a container name, based on:
    # - directory where the compose file is saved;
    # - container name (or label, if name isn't provided);
    # - a sequential id;
    #
    def generate_container_name(container_name, container_label)
      label = container_name || container_label
      id    = next_available_container_id

      "#{dir_name}_#{label}_#{id}"
    end
  end

  private_class_method :next_available_container_id
end
