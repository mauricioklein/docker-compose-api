require 'spec_helper'

describe ComposeContainer do
  context 'Object creation' do
    before(:all) do
      @attributes = {
        label: SecureRandom.hex,
        image: 'busybox:latest',
        name: SecureRandom.hex,
        links: ['service1:label', 'service2'],
        ports: ['3000', '8000:8000', '127.0.0.1:8001:8001'],
        volumes: ['/tmp'],
        command: 'ping -c 3 localhost',
        environment: ['ENVIRONMENT'],
        labels: { 'com.example.foo' => 'bar' }
      }

      @entry = ComposeContainer.new(@attributes)
    end

    it 'should prepare attributes correctly' do
      expect(@entry.attributes[:image]).to eq(@attributes[:image])
      expect(@entry.attributes[:name]).to match(/#{ComposeUtils.dir_name}_#{@attributes[:name]}_\d+/)
      expect(@entry.attributes[:links])
        .to eq({'service1' => 'label', 'service2' => 'service2'})
      expect(@entry.attributes[:volumes]).to eq(@attributes[:volumes])
      expect(@entry.attributes[:command]).to eq(@attributes[:command].split(' '))
      expect(@entry.attributes[:environment]).to eq(@attributes[:environment])
      expect(@entry.attributes[:labels]).to eq(@attributes[:labels])
    end

    it 'should map ports' do
      # Check ports structure
      expect(@entry.attributes[:ports].length).to eq(@attributes[:ports].length)

      # Port 1: '3000'
      port_entry = @entry.attributes[:ports][0]
      expect(port_entry.container_port).to eq('3000')
      expect(port_entry.host_ip).to eq(nil)
      expect(port_entry.host_port).to eq(nil)

      # Port 2: '8000:8000'
      port_entry = @entry.attributes[:ports][1]
      expect(port_entry.container_port).to eq('8000')
      expect(port_entry.host_ip).to eq(nil)
      expect(port_entry.host_port).to eq('8000')

      # Port 3: '127.0.0.1:8001:8001'
      port_entry = @entry.attributes[:ports][2]
      expect(port_entry.container_port).to eq('8001')
      expect(port_entry.host_ip).to eq('127.0.0.1')
      expect(port_entry.host_port).to eq('8001')
    end

    after(:all) do
      @entry.delete
    end
  end

  context 'From image' do
    before(:all) do
      @attributes = {
        label: SecureRandom.hex,
        image: 'busybox:latest',
        name: SecureRandom.hex,
        links: ['links:links'],
        volumes: ['/tmp'],
        command: 'ping -c 3 localhost',
        environment: ['ENVIRONMENT']
      }

      @entry = ComposeContainer.new(@attributes)
      @entry_autogen_name = ComposeContainer.new(@attributes.reject{|key| key == :name})
    end

    it 'should start/stop a container' do
      #Start container
      @entry.start
      expect(@entry.running?).to be true

      # Stop container
      @entry.stop
      expect(@entry.running?).to be false
    end

    it 'should provide container stats' do
      #Start container
      @entry.start
      expect(@entry.running?).to be true

      expect(@entry.stats).to_not be_nil

      # Stop container
      @entry.stop
      expect(@entry.running?).to be false
    end

    it 'should assign a given name to container' do
      #Start container
      @entry.start

      expect(@entry.stats['Name']).to match(/#{ComposeUtils.dir_name}_#{@attributes[:name]}_\d+/)

      # Stop container
      @entry.stop
    end

    it 'should assign label to container name when name is not given' do
      #Start container
      @entry_autogen_name.start

      expect(@entry_autogen_name.stats['Name']).to match(/#{ComposeUtils.dir_name}_#{@entry_autogen_name.attributes[:label]}_\d+/)

      # Stop container
      @entry_autogen_name.stop
    end

    after(:all) do
      @entry.delete
      @entry_autogen_name.delete
    end
  end

  context 'From Dockerfile' do
    before(:all) {
      @attributes = {
        label: 'foobar',
        build: File.expand_path('spec/docker-compose/fixtures/'),
        links: ['links:links'],
        volumes: ['/tmp']
      }

      @entry = ComposeContainer.new(@attributes)
    }

    after(:all) do
      Docker::Image.get(@entry.internal_image).remove(force: true)
      @entry.delete
    end

    it 'should start/stop a container' do
      #Start container
      @entry.start
      expect(@entry.running?).to be true

      # Stop container
      @entry.stop
      expect(@entry.running?).to be false
    end

    it 'should provide container stats' do
      #Start container
      @entry.start
      expect(@entry.running?).to be true

      expect(@entry.stats).to_not be_nil

      # Stop container
      @entry.stop
      expect(@entry.running?).to be false
    end
  end

  context 'Without image or Dockerfile' do
    before(:all) do
      attributes = {
        links: ['links:links'],
        volumes: ['/tmp'],
        command: 'ps aux',
        environment: ['ENVIRONMENT']
      }

      @entry = ComposeContainer.new(attributes)
    end

    it 'should not start a container' do
      expect{@entry.start}.to raise_error(ArgumentError)
    end

    after(:all) do
      @entry.delete
    end
  end

  context 'With environment as a hash' do
    before(:all) do
      @attributes = {
        image: 'busybox:latest',
        command: 'ping -c 3 localhost',
        environment: { ENVIRONMENT: 'VALUE' }
      }

      @entry = ComposeContainer.new(@attributes)
    end

    it 'should prepare environment attribute correctly' do
      expect(@entry.attributes[:environment]).to eq(%w(ENVIRONMENT=VALUE))
    end

    after(:all) do
      @entry.delete
    end
  end

  describe 'prepare_volumes' do
    let(:attributes) do
      { image: 'busybox:latest' }
    end

    it 'correctly parses container-only volumes' do
      attributes[:volumes] = ['/tmp']
      entry = ComposeContainer.new(attributes)
      volumes = entry.send(:prepare_volumes)
      expect(volumes).to eq({ '/tmp' => {} })
    end

    it 'correctly parses host-container mapped volumes' do
      attributes[:volumes] = ['./tmp:/tmp']
      entry = ComposeContainer.new(attributes)
      volumes = entry.send(:prepare_volumes)
      expect(volumes).to eq({ '/tmp' => { './tmp' => 'rw' } })
    end

    it 'correctly parses host-container mapped volumes with access rights' do
      attributes[:volumes] = ['./tmp:/tmp:ro']
      entry = ComposeContainer.new(attributes)
      volumes = entry.send(:prepare_volumes)
      expect(volumes).to eq({ '/tmp' => { './tmp' => 'ro' } })
    end
  end
end
