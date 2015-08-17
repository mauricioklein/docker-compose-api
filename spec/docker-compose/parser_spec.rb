require 'spec_helper'

describe DockerCompose do
  before(:all) do
    DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/sample1.yaml'))
  end

  it 'should be able to access Docker client' do
    expect(DockerCompose.getDockerClient.version).to_not be_nil
  end

  it 'should read a YAML file correctly' do
    expect(DockerCompose.containers.length).to eq(2)
  end

  it 'should start/stop all containers' do
    # Start containers
    puts 'STARTING CONTAINER SPEC...'
    DockerCompose.startContainers
    DockerCompose.containers.values.each do |container|
      puts "Inspect after start: #{container.dockerContainer.json.to_s}"
      expect(container.dockerContainer.json['State']['Running']).to be true
    end

    puts "Check now!!!"
    sleep 10

    puts "RUNNING CONTAINERS BEFORE STOP: #{DockerCompose.getDockerClient::Container.all()}"

    # Stop containers
    puts 'STOPING CONTAINER SPEC (sleep 20s)...'
    DockerCompose.stopContainers
    sleep 60
    puts 'Finished sleep'
    puts "RUNNING CONTAINERS AFTER STOP: #{DockerCompose.getDockerClient::Container.all()}"
    DockerCompose.containers.values.each do |container|
      puts "Inspect after stop: #{container.dockerContainer.json.to_s}"
      expect(container.dockerContainer.json['State']['Running']).to be false
    end
  end

  it 'should start/stop a single container' do
    firstContainer = DockerCompose.containers.keys.first
    lastContainer  = DockerCompose.containers.keys.last

    # Start a single container
    DockerCompose.startContainers([firstContainer])
    expect(DockerCompose.containers[firstContainer].dockerContainer.json['State']['Running']).to be true
    expect(DockerCompose.containers[lastContainer ].dockerContainer.json['State']['Running']).to be false

    # Stop containers
    DockerCompose.stopContainers([firstContainer])
    expect(DockerCompose.containers[firstContainer].dockerContainer.json['State']['Running']).to be false
    expect(DockerCompose.containers[lastContainer ].dockerContainer.json['State']['Running']).to be false
  end

  after(:all) do
    DockerCompose.containers.values.each do |container|
      container.delete
    end
  end
end
