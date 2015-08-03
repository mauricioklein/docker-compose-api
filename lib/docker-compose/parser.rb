require 'yaml'
require 'docker'

module DockerCompose::Parser
  def self.getDockerClient()
    Docker
  end

  def self.load(filepath)
    unless File.exist?(filepath)
      puts "Compose file doesn't exists"
    end

    @entries = Array.new
    _compose_entries = YAML.load_file(filepath)
    _compose_entries.each do |entry|
      attr_hash = {
        'id'      => entry[0],
        'build'   => entry[1]['build'],
        'image'   => entry[1]['image'],
        'ports'   => entry[1]['ports'],
        'volumes' => entry[1]['volumes'],
        'links'   => entry[1]['links']
      }
      @entries << ComposeEntry.new(attr_hash)
    end
  end

  def self.start
    # First, download/build all necessary images
    @entries.each do |entry|
      puts "Entry: #{entry.inspect.to_json}"
      #unless entry['image'].nil?
      #  puts "Downloading image: #{entry['image']}"
      #  Docker::Image.create('fromImage' => entry['image'], 'tag' => 'latest')
      #end
    end

    # Now, start all necessary containers
    @entries.each do |entry|
      #unless entry['image'].nil?
      #  puts "Starting container from image: #{entry['image']}"
      #  Docker::Container.create('Image' => entry['image']).start
      #end
    end
  end
end
