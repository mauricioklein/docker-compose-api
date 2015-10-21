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

  it 'should start/stop/kill a single container' do
    first_entry = DockerCompose.entries.first.compose_attributes[:label]
    last_entry  = DockerCompose.entries.last.compose_attributes[:label]

    # Start a single container
    DockerCompose.start([first_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be true
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be false

    # Stop container
    DockerCompose.stop([first_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be false
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be false

    # Start another container
    DockerCompose.start([last_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be false
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be true

    # Kill container
    DockerCompose.kill([last_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be false
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be false
  end

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
