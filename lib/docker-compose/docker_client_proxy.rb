require 'singleton'
require 'docker'

class DockerClientProxy
  include Singleton

  def pull_image(image)
    Docker::Image.create('fromImage' => image)
  end

  def build_image(dockerfile_content)
    Docker::Image.build(dockerfile_content)
  end

  def create_container(attributes)
    Docker::Container.create(attributes)
  end
end
