require 'docker'

class ComposeEntry
  attr_accessor :label, :build, :expose, :command, :baseImage, :tag, :dockerImage, :dockerContainer

  def initialize(hash_attributes)
    @label   = hash_attributes['label'  ]
    @build   = hash_attributes['build'  ]
    @command = hash_attributes['command']

    # Split image in baseImage and Tag
    unless hash_attributes['image'].nil?
      image_split = hash_attributes['image'].split(':')
      @baseImage = image_split[0]
      @tag = image_split[1] || 'latest'
    end

    unless @command.nil?
      @command = @command.split(' ')
    end

    @expose = Hash.new
    unless hash_attributes['expose'].nil?
      hash_attributes['expose'].each do |port|
        @expose[port] = {}
      end
    end

    @dockerImage = nil
    @dockerContainer = nil
  end

  public
    def prepareImage
      unless @baseImage.nil?
        puts("Downloading image: #{@baseImage}:#{@tag}")
        @dockerImage = Docker::Image.create('fromImage' => @baseImage, 'tag' => @tag)
      end

      unless @build.nil?
        puts("Building image from dir: #{@build}")
        @dockerImage = Docker::Image.build_from_dir(@build)
      end
    end

    # TODO: build container from local image
    def prepareContainer
      puts("Preparing container: BaseImage: #{@baseImage}, Tag: #{@tag}, Expose: #{@expose}, Cmd: #{@command}")
      @dockerContainer = Docker::Container.create('Image' => "#{@baseImage}:#{@tag}", 'Cmd' => @command, 'ExposedPorts' => @expose)
    end

    def start
      @dockerContainer.start unless @dockerContainer.nil?
    end

    def stop
      @dockerContainer.kill unless @dockerContainer.nil?
    end

    def delete
      @dockerContainer.delete(:force => true) unless @dockerContainer.nil?
      @dockerContainer = nil
    end
end
