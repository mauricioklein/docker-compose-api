module ComposeUtils
  @dir_name = File.split(Dir.pwd).last.gsub(/[-_]/, '')
  @current_container_id = nil

  #
  # Returns the directory name where compose
  # file is saved (used in container naming)
  #
  def self.dir_name
    @dir_name
  end

  #
  # Provides the next available ID
  # to container names
  #
  def self.next_available_id
    if @current_container_id.nil?
      # Discovery the max id used by already running containers
      # (default to '0' if no container is running)
      @current_container_id = Docker::Container.all(all: true).map {|c| c.info['Names'].last.split(/_/).last.to_i}.flatten.max || 0
    end

    @current_container_id += 1
  end

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

  #
  # Format ports from running container
  #
  def self.format_ports_from_running_container(port_entry)
    entries = []
    container_port = nil
    host_ip = nil
    host_port = nil

    if port_entry.nil?
      return entries
    end

    port_entry.each do |key, value|
      container_port = key.gsub(/\D/, '').to_i
      # Ports that are EXPOSEd but not published won't have a Host IP/Port,
      # only a Container Port.
      if value.nil?
        host_ip = ''
        host_port = ''
      else
        host_ip = value.first['HostIp']
        host_port = value.first['HostPort']
      end

      entries << "#{container_port}:#{host_ip}:#{host_port}"
    end

    entries
  end

  #
  # Generate a pair key:hash with
  # format {service:label}
  #
  # The label will be the conainer name if not specified.
  #
  def self.format_links(links_array)
    links = {}

    return if links_array.nil?

    links_array.each do |link|
      parts = link.split(':')

      case parts.length
        when 1
          links[parts[0]] = parts[0]

        when 2
          links[parts[0]] = parts[1]
      end
    end

    links
  end

  #
  # Generate a container name, based on:
  # - directory where the compose file is saved;
  # - container name (or label, if name isn't provided);
  # - a sequential index;
  #
  def self.generate_container_name(container_name, container_label)
    label = container_name.nil? ? container_label : container_name
    index = next_available_id

    "#{@dir_name}_#{label}_#{index}"
  end

  private_class_method :next_available_id
end
