module ComposeUtils
  #
  # Format a given docker image in a complete structure (base image + tag)
  #
  def self.format_image(image)
    base_image = nil
    tag = nil

    if image.nil?
      return nil
    end

    if image.index(':').nil?
      base_image = image
      tag = 'latest'
    else
      image_split = image.split(':')
      base_image = image_split[0]
      tag = image_split[1]
    end

    "#{base_image}:#{tag}"
  end

  #
  # Transform docker command from string to an array of commands
  #
  def self.format_command(command)
    command.nil? ? nil : command.split(' ')
  end

  #
  # Read a port specification in string format
  # and create a compose port structure
  #
  def self.format_port(port_entry)
    compose_port = nil
    container_port = nil
    host_port = nil
    host_ip = nil

    port_parts = port_entry.split(':')

    case port_parts.length
      # [container port]
      when 1
        compose_port = ComposePort.new(port_parts[0])

      # [host port]:[container port]
      when 2
        compose_port = ComposePort.new(port_parts[1], port_parts[0])

      # [host ip]:[host port]:[container port]
      when 3
        compose_port = ComposePort.new(port_parts[2], port_parts[1], port_parts[0])
    end

    compose_port
  end
end
