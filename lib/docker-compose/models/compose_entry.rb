class ComposeEntry
  def initialize(id, build, ports, volumes, links)
    @id = id
    @build = build
    @ports = ports
    @volumes = volumes
    @links = links
  end
end
