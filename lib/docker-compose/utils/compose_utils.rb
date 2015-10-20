module ComposeUtils
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

  def self.format_command(command)
    command.nil? ? nil : command.split(' ')
  end
end
