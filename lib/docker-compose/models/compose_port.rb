class ComposePort
  attr_reader :container_port, :host_ip, :host_port

  def initialize(params)
    @container_port = params[:container_port]
    @host_ip = params[:host_ip]
    @host_port = params[:host_port]
  end
end
