# Support multiple versions for docker-compose configs.
class DockerComposeConfig
  attr_reader :version, :services, :volumes, :networks

  def initialize(filepath)
    parse_docker_compose_config(filepath)
  end

  # Parse the docker-compose config
  def parse_docker_compose_config(filepath)
    f = File.read(filepath)
    f = f.gsub(/\$([a-zA-Z_]+[a-zA-Z0-9_]*)|\$\{(.+)\}/) { ENV[$1 || $2] }

    config = YAML.load(f)

    unless config
      config = YAML.load('{}')
    end

    case (config['version'])
    when 2,'2'
      parse_version_2(config)
    else
      parse_version_1(config)
    end
  end

  def parse_version_2(config)
    @version = 2
    @services = config['services']
    @volumes = config['volumes']
    @networks = config['networks']
  end

  def parse_version_1(config)
    @version = 1
    @services = config
    @volumes = nil
    @networks = nil
  end
end
