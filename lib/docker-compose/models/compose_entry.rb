require 'docker'

class ComposeEntry
  def initialize(hash_attributes)
    @id      = hash_attributes['id'     ]
    @build   = hash_attributes['build'  ]
    @ports   = hash_attributes['ports'  ]
    @volumes = hash_attributes['volumes']
    @links   = hash_attributes['links'  ]
    @command = hash_attributes['command']

    # Split image in baseImage and Tag
    unless hash_attributes['image'].nil?
      image_split = hash_attributes['image'].split(':')
      @baseImage = image_split[0]
      @tag = image_split[1] || 'latest'
    end

    @ports = Hash.new
    unless hash_attributes['ports'].nil?
      hash_attributes['ports'].each do |port|
        port_split = port.split(':')
        host_port, container_port = port_split[0], port_split[1]
        @ports[host_port] = container_port
      end
    end

    unless @command.nil?
      @command = @command.split(' ')
    end

    @dockerImage = nil
    @dockerContainer = nil

    self.prepareImage
    self.prepareContainer
  end

  protected
    def prepareImage
      unless @baseImage.nil?
        puts "Downloading image: #{@baseImage}:#{@tag}"
        @dockerImage = Docker::Image.create('fromImage' => @baseImage, 'tag' => @tag)
      end

      unless @build.nil?
        puts "Building image from dir: #{@build}"
        @dockerImage = Docker::Image.build_from_dir(@build)
      end
    end

    # TODO: build container from local image
    def prepareContainer
      puts "Preparing container - Image: #{@baseImage}:#{@tag}, ExposedPorts: #{@ports}, Cmd: #{@command}"
      @dockerContainer = Docker::Container.create(
                            'Image'        => "#{@baseImage}:#{@tag}",
                            'ExposedPorts' => @ports,
                            'Cmd'          => @command
                         )
    end

  public
    def start
      @dockerContainer.start unless @dockerContainer.nil?
    end

    def stop
      @dockerContainer.stop unless @dockerContainer.nil?
    end
end
