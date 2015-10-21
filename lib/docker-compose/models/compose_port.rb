class ComposePort
  attr_reader :container_port, :host_ip, :host_port

  def initialize(container_port, host_port = nil, host_ip = nil)
    @container_port = container_port
    @host_ip = host_ip
    @host_port = host_port
  end
end
