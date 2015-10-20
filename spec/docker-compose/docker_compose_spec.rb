require 'spec_helper'

describe DockerCompose do
  before(:all) do
    DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/sample1.yaml'))
  end

  it 'should be able to access Docker client' do
    expect(DockerCompose.getDockerClient.version).to_not be_nil
  end

  it 'should read a YAML file correctly' do
    expect(DockerCompose.entries.length).to eq(2)
  end

  it 'should start/stop all containers' do
    # Start containers to test Stop
    DockerCompose.start_containers
    DockerCompose.entries.each do |entry|
      expect(entry.container.json['State']['Running']).to be true
    end

    # Stop containers
    DockerCompose.stop_containers
    DockerCompose.entries.each do |entry|
      expect(entry.container.json['State']['Running']).to be false
    end

    # Start containers to test Kill
    DockerCompose.start_containers
    DockerCompose.entries.each do |entry|
      expect(entry.container.json['State']['Running']).to be true
    end

    # Kill containers
    DockerCompose.kill_containers
    DockerCompose.entries.each do |entry|
      expect(entry.container.json['State']['Running']).to be false
    end
  end

  it 'should start/stop/kill a single container' do
    first_entry = DockerCompose.entries.first.compose_attributes[:label]
    last_entry  = DockerCompose.entries.last.compose_attributes[:label]

    # Start a single container
    DockerCompose.start_containers([first_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be true
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be false

    # Stop container
    DockerCompose.stop_containers([first_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be false
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be false

    # Start another container
    DockerCompose.start_containers([last_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be false
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be true

    # Kill container
    DockerCompose.kill_containers([last_entry])
    expect(DockerCompose.entries(first_entry).container.json['State']['Running']).to be false
    expect(DockerCompose.entries(last_entry).container.json['State']['Running']).to be false
  end

  after(:all) do
    DockerCompose.entries.each do |entry|
      entry.container.delete
    end
  end
end
