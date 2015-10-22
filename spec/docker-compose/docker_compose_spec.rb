require 'spec_helper'

describe DockerCompose do
  before(:all) do
    @compose = DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/sample1.yaml'))
  end

  it 'should be able to access gem version' do
    expect(DockerCompose.version).to_not be_nil
  end

  it 'should be able to access Docker client' do
    expect(DockerCompose.docker_client).to_not be_nil
  end

  it 'should read a YAML file correctly' do
    expect(@compose.containers.length).to eq(2)
  end

  context 'All containers' do
    it 'should start/stop all containers' do
      # Start containers to test Stop
      @compose.start
      @compose.containers.values.each do |container|
        expect(container.running?).to be true
      end

      # Stop containers
      @compose.stop
      @compose.containers.values.each do |container|
        expect(container.running?).to be false
      end
    end

    it 'should start/kill all containers' do
      # Start containers to test Kill
      @compose.start
      @compose.containers.values.each do |container|
        expect(container.running?).to be true
      end

      # Kill containers
      @compose.kill
      @compose.containers.values.each do |container|
        expect(container.running?).to be false
      end
    end
  end

  context 'Single container' do
    context 'Without dependencies' do
      it 'should start/stop a single container' do
        ubuntu = @compose.containers.values.first.attributes[:label]
        redis  = @compose.containers.values.last.attributes[:label]

        # Should start Redis only, since it hasn't dependencies
        @compose.start([redis])
        expect(@compose.containers[ubuntu].running?).to be false
        expect(@compose.containers[redis].running?).to be true

        # Stop Redis
        @compose.stop([redis])
        expect(@compose.containers[ubuntu].running?).to be false
        expect(@compose.containers[redis].running?).to be false
      end

      it 'should start/kill a single container' do
        ubuntu = @compose.containers.values.first.attributes[:label]
        redis  = @compose.containers.values.last.attributes[:label]

        # Should start Redis only, since it hasn't dependencies
        @compose.start([redis])
        expect(@compose.containers[ubuntu].running?).to be false
        expect(@compose.containers[redis].running?).to be true

        # Stop Redis
        @compose.kill([redis])
        expect(@compose.containers[ubuntu].running?).to be false
        expect(@compose.containers[redis].running?).to be false
      end
    end # context 'Without dependencies'

    context 'With dependencies' do
      it 'should start/stop a single container' do
        ubuntu = @compose.containers.values.first.attributes[:label]
        redis  = @compose.containers.values.last.attributes[:label]

        # Should start Ubuntu and Redis, since Ubuntu depends on Redis
        @compose.start([ubuntu])
        expect(@compose.containers[ubuntu].running?).to be true
        expect(@compose.containers[redis].running?).to be true

        # Stop Ubuntu (Redis keeps running)
        @compose.stop([ubuntu])
        expect(@compose.containers[ubuntu].running?).to be false
        expect(@compose.containers[redis].running?).to be true

        # Stop Redis
        @compose.stop([redis])
        expect(@compose.containers[redis].running?).to be false
      end

      it 'should start/kill a single container' do
        ubuntu = @compose.containers.values.first.attributes[:label]
        redis  = @compose.containers.values.last.attributes[:label]

        # Should start Ubuntu and Redis, since Ubuntu depends on Redis
        @compose.start([ubuntu])
        expect(@compose.containers[ubuntu].running?).to be true
        expect(@compose.containers[redis].running?).to be true

        # Kill Ubuntu (Redis keeps running)
        @compose.kill([ubuntu])
        expect(@compose.containers[ubuntu].running?).to be false
        expect(@compose.containers[redis].running?).to be true

        # Kill Redis
        @compose.kill([redis])
        expect(@compose.containers[redis].running?).to be false
      end
    end # context 'with dependencies'
  end # context 'Single container'

  it 'should assign ports' do
    ubuntu = @compose.containers.values.first

    # Start container
    ubuntu.start

    port_bindings = ubuntu.stats['HostConfig']['PortBindings']
    exposed_ports = ubuntu.stats['Config']['ExposedPorts']

    # Check port bindings
    expect(port_bindings.length).to eq(3)
    expect(port_bindings.key?('3000/tcp')).to be true
    expect(port_bindings.key?('8000/tcp')).to be true
    expect(port_bindings.key?('8001/tcp')).to be true

    # Check exposed ports
    expect(exposed_ports.key?('3000/tcp')).to be true
    expect(exposed_ports.key?('8000/tcp')).to be true
    expect(exposed_ports.key?('8001/tcp')).to be true

    # Stop container
    ubuntu.stop
  end

  it 'should link containers' do
    ubuntu = @compose.containers.values.first

    # Start container
    ubuntu.start

    # Ubuntu should be linked to Redis
    links = ubuntu.stats['HostConfig']['Links']
    expect(links.length).to eq(1)

    # Stop container
    ubuntu.stop
  end

  after(:all) do
    @compose.containers.values.each do |entry|
      entry.delete
    end
  end
end
