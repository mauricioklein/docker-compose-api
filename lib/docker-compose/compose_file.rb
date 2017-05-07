require 'yaml'
require 'hash_dot'

class ComposeFile
  attr_reader :content

  def initialize(filepath)
    load_compose_file(filepath)
  end

  def version
    content.version
  end

private

  def load_compose_file(filepath)
    file =
      File
        .read(filepath)
        .gsub(/\$([a-zA-Z_]+[a-zA-Z0-9_]*)|\$\{(.+)\}/) { ENV[$1 || $2] }


    @content = YAML.load(file).to_dot
  rescue TypeError, StandardError => e
    fail ComposeFileLoadException.new(e)
  end

  def parse_yaml(file)
    yaml = YAML.load(file)
    fail 'Could not read compose file' unless yaml
  end
end

class ComposeFileLoadException < StandardError
  def initialize(error)
    super(error)
  end
end
