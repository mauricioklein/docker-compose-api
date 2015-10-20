require 'spec_helper'

describe ComposeEntry do
  context 'Object creation' do
    it 'should prepare the attributes correctly' do
      attributes = {
        image: 'ubuntu:latest',
        links: ['links:links'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      entry = ComposeEntry.new(attributes)

      expect(entry.compose_attributes[:image]).to eq(attributes[:image])
      expect(entry.compose_attributes[:links]).to eq(attributes[:links])
      expect(entry.compose_attributes[:volumes]).to eq(attributes[:volumes])
      expect(entry.compose_attributes[:command]).to eq(attributes[:command].split(' '))
      expect(entry.compose_attributes[:environment]).to eq(attributes[:environment])
    end

    it 'should not accept both image and build commands on the same compose entry' do
      attributes = {
        image: 'ubuntu:latest',
        build: '.',
        links: ['links:links'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      expect{ComposeEntry.new(attributes)}.to raise_error(ArgumentError)
    end

    it 'should not accept compose entry without either image and build commands' do
      attributes = {
        links: ['links:links'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      expect{ComposeEntry.new(attributes)}.to raise_error(ArgumentError)
    end

    it 'should start and stop a container' do
      attributes = {
        image: 'ubuntu:latest',
        links: ['links:links'],
        volumes: {'/tmp' => {}},
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      entry = ComposeEntry.new(attributes)

      #Start container
      entry.start
      expect(entry.container.json['State']['Running']).to be true

      # Stop container
      entry.stop
      expect(entry.container.json['State']['Running']).to be false
    end
  end
end
