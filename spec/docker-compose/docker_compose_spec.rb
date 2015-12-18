require 'spec_helper'

describe DockerCompose do
  before(:all) do
    @compose = DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/compose_1.yaml'))
  end

  it 'should be able to access gem version' do
    expect(DockerCompose.version).to_not be_nil
  end

  it 'should be able to access Docker client' do
    expect(DockerCompose.docker_client).to_not be_nil
  end

  it 'should read a YAML file correctly' do
    expect(@compose.containers.length).to eq(3)
  end

  it 'should raise error when reading an invalid YAML file' do
    expect{DockerCompose.load('')}.to raise_error(ArgumentError)
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
        container1 = @compose.containers.values.first.attributes[:label]
        container2 = @compose.containers.values[1].attributes[:label]

        # Should start Redis only, since it hasn't dependencies
        @compose.start([container2])
        expect(@compose.containers[container1].running?).to be false
        expect(@compose.containers[container2].running?).to be true

        # Stop Redis
        @compose.stop([container2])
        expect(@compose.containers[container1].running?).to be false
        expect(@compose.containers[container2].running?).to be false
      end

      it 'should start/kill a single container' do
        container1 = @compose.containers.values.first.attributes[:label]
        container2 = @compose.containers.values[1].attributes[:label]

        # Should start Redis only, since it hasn't dependencies
        @compose.start([container2])
        expect(@compose.containers[container1].running?).to be false
        expect(@compose.containers[container2].running?).to be true

        # Stop Redis
        @compose.kill([container2])
        expect(@compose.containers[container1].running?).to be false
        expect(@compose.containers[container2].running?).to be false
      end
    end # context 'Without dependencies'

    context 'With dependencies' do
      it 'should start/stop a single container' do
        container1 = @compose.containers.values.first.attributes[:label]
        container2 = @compose.containers.values[1].attributes[:label]

        # Should start Ubuntu and Redis, since Ubuntu depends on Redis
        @compose.start([container1])
        expect(@compose.containers[container1].running?).to be true
        expect(@compose.containers[container2].running?).to be true

        # Stop Ubuntu (Redis keeps running)
        @compose.stop([container1])
        expect(@compose.containers[container1].running?).to be false
        expect(@compose.containers[container2].running?).to be true

        # Stop Redis
        @compose.stop([container2])
        expect(@compose.containers[container2].running?).to be false
      end

      it 'should start/kill a single container' do
        container1 = @compose.containers.values.first.attributes[:label]
        container2 = @compose.containers.values[1].attributes[:label]

        # Should start Ubuntu and Redis, since Ubuntu depends on Redis
        @compose.start([container1])
        expect(@compose.containers[container1].running?).to be true
        expect(@compose.containers[container2].running?).to be true

        # Kill Ubuntu (Redis keeps running)
        @compose.kill([container1])
        expect(@compose.containers[container1].running?).to be false
        expect(@compose.containers[container2].running?).to be true

        # Kill Redis
        @compose.kill([container2])
        expect(@compose.containers[container2].running?).to be false
      end

      it 'should be able to ping a dependent container' do
        container1 = @compose.containers.values.first.attributes[:label]
        container2 = @compose.containers.values[1].attributes[:label]

        # Start all containers
        @compose.start
        expect(@compose.containers[container1].running?).to be true
        expect(@compose.containers[container2].running?).to be true

        # Ping container2 from container1
        ping_response = @compose.containers[container1].container.exec(['ping', '-c', '3', 'busybox2'])
        expect(ping_response[2]).to eq(0) # Status 0 = OK
      end

      it 'should be able to ping a dependent aliased container' do
        container2 = @compose.containers.values[1].attributes[:label]
        container3 = @compose.containers.values[2].attributes[:label]

        # Start all containers
        @compose.start
        expect(@compose.containers[container2].running?).to be true
        expect(@compose.containers[container3].running?).to be true

        # Ping container3 from container1
        ping_response = @compose.containers[container3].container.exec(['ping', '-c', '3', 'bb2'])
        expect(ping_response[2]).to eq(0) # Status 0 = OK
      end
    end # context 'with dependencies'
  end # context 'Single container'

  it 'should assign ports' do
    container1 = @compose.containers.values.first

    # Start container
    container1.start

    port_bindings = container1.stats['HostConfig']['PortBindings']
    exposed_ports = container1.stats['Config']['ExposedPorts']

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
    container1.stop
  end

  it 'should link containers' do
    container1 = @compose.containers.values.first

    # Start container
    container1.start

    # Ubuntu should be linked to Redis
    links = container1.stats['HostConfig']['Links']
    expect(links.length).to eq(1)

    # Stop container
    container1.stop
  end

  it 'supports setting environment as array' do
    container1 = @compose.containers.values.first

    # Start container
    container1.start

    env = container1.stats['Config']['Env']
    expect(env).to eq(%w(MYENV1=variable1))

    # Stop container
    container1.stop
  end

  it 'supports setting environment as hash' do
    container1 = @compose.containers.values[1]

    # Start container
    container1.start

    env = container1.stats['Config']['Env']
    expect(env).to eq(%w(MYENV2=variable2))

    # Stop container
    container1.stop
  end

  after(:all) do
    @compose.containers.values.each do |entry|
      entry.delete
    end
  end
end
