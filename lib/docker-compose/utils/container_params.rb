module Container
  class Params
    attr_reader :raw_attr

    def initialize(attr)
      @raw_attr = attr
    end

    def to_h
      {
        label: label,
        loaded_from_environment: loaded_from_environment?,
        name: name,
        image: image,
        build: build,
        links: links,
        ports: ports,
        volumes: volumes,
        command: command,
        environment: environment,
        labels: labels
      }.reject{ |key, value| value.nil? }
    end

    def label
      raw_attr[:label]
    end

    def loaded_from_environment?
      raw_attr[:loaded_from_environment] || false
    end

    def name
      raw_attr[:full_name] || ComposeUtils.generate_container_name(raw_attr[:name], raw_attr[:label])
    end

    def image
      ComposeUtils.format_image(raw_attr[:image])
    end

    def build
      raw_attr[:build]
    end

    def links
      ComposeUtils.format_links(raw_attr[:links])
    end

    def ports
      prepare_ports(raw_attr[:ports])
    end

    def volumes
      raw_attr[:volumes]
    end

    def command
      ComposeUtils.format_command(raw_attr[:command])
    end

    def environment
      prepare_environment(raw_attr[:environment])
    end

    def labels
      prepare_labels(raw_attr[:labels])
    end

    def prepare_ports(port_entries)
      return nil if port_entries.nil?
      port_entries.map { |port_entry| ComposeUtils.format_port(port_entry) }
    end

    def prepare_environment(env_entries)
      env_entries.is_a?(Hash) ?
        env_entries.to_a.map { |x| x.join('=') } :
        env_entries
    end

    def prepare_labels(labels)
      labels.is_a?(Array) ? Hash[labels.map { |label| label.split('=') }] : labels
    end
  end
end
