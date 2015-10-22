require 'spec_helper'

describe DockerCompose do
  before(:all) do
    DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/sample1.yaml'))
  end

  it 'should be able to access Docker client' do
    expect(DockerCompose.docker_client).to_not be_nil
  end

  it 'should read a YAML file correctly' do
    expect(DockerCompose.entries.length).to eq(2)
  end

  context 'All containers' do
    it 'should start/stop all containers' do
      # Start containers to test Stop
      DockerCompose.start
      DockerCompose.entries.each do |entry|
        expect(entry.container.json['State']['Running']).to be true
      end

      # Stop containers
      DockerCompose.stop
      DockerCompose.entries.each do |entry|
        expect(entry.container.json['State']['Running']).to be false
      end
    end

    it 'should start/kill all containers' do
      # Start containers to test Kill
      DockerCompose.start
      DockerCompose.entries.each do |entry|
        expect(entry.container.json['State']['Running']).to be true
      end

      # Kill containers
      DockerCompose.kill
      DockerCompose.entries.each do |entry|
        expect(entry.container.json['State']['Running']).to be false
      end
    end
  end

  context 'Single container' do
    context 'Without dependencies' do
      it 'should start/stop a single container' do
        ubuntu = DockerCompose.entries.first.compose_attributes[:label]
        redis  = DockerCompose.entries.last.compose_attributes[:label]

        # Should start Redis only, since it hasn't dependencies
        DockerCompose.start([redis])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be false
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be true

        # Stop Redis
        DockerCompose.stop([redis])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be false
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be false
      end

      it 'should start/kill a single container' do
        ubuntu = DockerCompose.entries.first.compose_attributes[:label]
        redis  = DockerCompose.entries.last.compose_attributes[:label]

        # Should start Redis only, since it hasn't dependencies
        DockerCompose.start([redis])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be false
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be true

        # Stop Redis
        DockerCompose.kill([redis])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be false
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be false
      end
    end # context 'Without dependencies'

    context 'With dependencies' do
      it 'should start/stop a single container' do
        ubuntu = DockerCompose.entries.first.compose_attributes[:label]
        redis  = DockerCompose.entries.last.compose_attributes[:label]

        # Should start Ubuntu and Redis, since Ubuntu depends on Redis
        DockerCompose.start([ubuntu])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be true
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be true

        # Stop Ubuntu (Redis keeps running)
        DockerCompose.stop([ubuntu])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be false
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be true

        # Stop Redis
        DockerCompose.stop([redis])
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be false
      end

      it 'should start/kill a single container' do
        ubuntu = DockerCompose.entries.first.compose_attributes[:label]
        redis  = DockerCompose.entries.last.compose_attributes[:label]

        # Should start Ubuntu and Redis, since Ubuntu depends on Redis
        DockerCompose.start([ubuntu])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be true
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be true

        # Kill Ubuntu (Redis keeps running)
        DockerCompose.kill([ubuntu])
        expect(DockerCompose.entries(ubuntu).container.json['State']['Running']).to be false
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be true

        # Kill Redis
        DockerCompose.kill([redis])
        expect(DockerCompose.entries(redis).container.json['State']['Running']).to be false
      end
    end # context 'with dependencies'
  end # context 'Single container'

  it 'should assign ports' do
    ubuntu = DockerCompose.entries.first

    # Start container
    ubuntu.start

    port_bindings = ubuntu.container.json['HostConfig']['PortBindings']
    exposed_ports = ubuntu.container.json['Config']['ExposedPorts']

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

  after(:all) do
    DockerCompose.entries.each do |entry|
      entry.container.delete
    end
  end
end
