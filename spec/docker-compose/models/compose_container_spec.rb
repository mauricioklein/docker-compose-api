require 'spec_helper'

describe ComposeContainer do
  context 'Object creation' do
    it 'should prepare the attributes correctly' do
      attributes = {
        image: 'ubuntu:latest',
        links: ['links:links'],
        ports: ['3000', '8000:8000', '127.0.0.1:8001:8001'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      entry = ComposeContainer.new(attributes)

      expect(entry.attributes[:image]).to eq(attributes[:image])
      expect(entry.attributes[:links]).to eq(attributes[:links])
      expect(entry.attributes[:volumes]).to eq(attributes[:volumes])
      expect(entry.attributes[:command]).to eq(attributes[:command].split(' '))
      expect(entry.attributes[:environment]).to eq(attributes[:environment])

      # Check ports structure
      expect(entry.attributes[:ports].length).to eq(attributes[:ports].length)

      # Port 1: '3000'
      port_entry = entry.attributes[:ports][0]
      expect(port_entry.container_port).to eq('3000')
      expect(port_entry.host_ip).to eq(nil)
      expect(port_entry.host_port).to eq(nil)

      # Port 2: '8000:8000'
      port_entry = entry.attributes[:ports][1]
      expect(port_entry.container_port).to eq('8000')
      expect(port_entry.host_ip).to eq(nil)
      expect(port_entry.host_port).to eq('8000')

      # Port 3: '127.0.0.1:8001:8001'
      port_entry = entry.attributes[:ports][2]
      expect(port_entry.container_port).to eq('8001')
      expect(port_entry.host_ip).to eq('127.0.0.1')
      expect(port_entry.host_port).to eq('8001')
    end
  end

  context 'Start container' do
    it 'should start/stop a container from image' do
      attributes = {
        image: 'ubuntu:latest',
        links: ['links:links'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      entry = ComposeContainer.new(attributes)

      #Start container
      entry.start
      expect(entry.running?).to be true

      # Stop container
      entry.stop
      expect(entry.running?).to be false
    end

    it 'should start/stop a container from build' do
      attributes = {
        build: File.expand_path('spec/docker-compose/fixtures/'),
        links: ['links:links'],
        volumes: {'/tmp' => {}}
      }

      entry = ComposeContainer.new(attributes)

      #Start container
      entry.start
      expect(entry.running?).to be true

      # Stop container
      entry.stop
      expect(entry.running?).to be false
    end

    it 'should not start a container without either image and build commands' do
      attributes = {
        links: ['links:links'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      entry = ComposeContainer.new(attributes)
      expect{entry.start}.to raise_error(ArgumentError)
    end
  end
end
