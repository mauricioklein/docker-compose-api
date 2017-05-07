module ImageUtils
  def self.pull_image(image_name)
    DockerClientProxy.instance.pull_image(image_name)
  end

  def self.build_image_from_file(filepath)
    random_name = SecureRandom.hex
    DockerClientProxy.instance.build_from_dir(filepath, t: random_name)
  end
end
