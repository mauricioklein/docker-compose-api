require 'spec_helper'

describe DockerCompose do
  context 'Without memory' do
    before(:each) {
      @compose = DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/compose_1.yaml'))
    }

    after(:each) do
      @compose.delete
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

      it 'should start/delete all containers' do
        # Start containers to test Delete
        @compose.start
        @compose.containers.values.each do |container|
          expect(container.running?).to be true
        end

        # Delete containers
        @compose.delete
        expect(@compose.containers.empty?).to be true
      end
    end

    context 'Single container' do
      context 'Without dependencies' do
        it 'should start/stop a single container' do
          container1 = @compose.containers.values.first.attributes[:label]
          container2 = @compose.containers.values[1].attributes[:label]

          @compose.start([container2])
          expect(@compose.containers[container1].running?).to be false
          expect(@compose.containers[container2].running?).to be true

          @compose.stop([container2])
          expect(@compose.containers[container1].running?).to be false
          expect(@compose.containers[container2].running?).to be false
        end

        it 'should start/kill a single container' do
          container1 = @compose.containers.values.first.attributes[:label]
          container2 = @compose.containers.values[1].attributes[:label]

          @compose.start([container2])
          expect(@compose.containers[container1].running?).to be false
          expect(@compose.containers[container2].running?).to be true

          @compose.kill([container2])
          expect(@compose.containers[container1].running?).to be false
          expect(@compose.containers[container2].running?).to be false
        end
      end

      context 'With dependencies' do
        it 'should start/stop a single container' do
          container1 = @compose.containers.values.first.attributes[:label]
          container2 = @compose.containers.values[1].attributes[:label]

          @compose.start([container1])
          expect(@compose.containers[container1].running?).to be true
          expect(@compose.containers[container2].running?).to be true

          @compose.stop([container1])
          expect(@compose.containers[container1].running?).to be false
          expect(@compose.containers[container2].running?).to be true

          @compose.stop([container2])
          expect(@compose.containers[container2].running?).to be false
        end

        it 'should start/kill a single container' do
          container1 = @compose.containers.values.first.attributes[:label]
          container2 = @compose.containers.values[1].attributes[:label]

          @compose.start([container1])
          expect(@compose.containers[container1].running?).to be true
          expect(@compose.containers[container2].running?).to be true

          @compose.kill([container1])
          expect(@compose.containers[container1].running?).to be false
          expect(@compose.containers[container2].running?).to be true

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
      end
    end

    it 'should assign ports' do
      container = @compose.get_containers_by(label: 'busybox1').first

      # Start container
      container.start

      port_bindings = container.stats['HostConfig']['PortBindings']
      exposed_ports = container.stats['Config']['ExposedPorts']

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
      container.stop
    end

    it 'should link containers' do
      container = @compose.get_containers_by(label: 'busybox1').first

      # Start container
      container.start

      # Ubuntu should be linked to Redis
      links = container.stats['HostConfig']['Links']
      expect(links.length).to eq(1)

      # Stop container
      container.stop
    end

    it 'binds volumes' do
      container = @compose.get_containers_by(label: 'busybox1').first

      # Start container
      container.start

      volumes = container.stats['HostConfig']['Binds']
      expect(volumes).to match_array(['/tmp/test:/tmp:ro'])

      # Stop container
      container.stop
    end

    it 'supports setting environment as array' do
      container = @compose.get_containers_by(label: 'busybox1').first

      # Start container
      container.start

      env = container.stats['Config']['Env']
      expect(env).to include('MYENV1=variable1')

      # Stop container
      container.stop
    end

    it 'supports setting environment as hash' do
      container = @compose.get_containers_by(label: 'busybox2').first

      # Start container
      container.start

      env = container.stats['Config']['Env']
      expect(env).to include('MYENV2=variable2')

      # Stop container
      container.stop
    end

    it 'supports setting labels as an array' do
      container = @compose.get_containers_by(label: 'busybox1').first

      # Start container
      container.start

      env = container.stats['Config']['Labels']
      expect(env['com.example.foo']).to eq('bar')

      # Stop container
      container.stop
    end

    it 'supports setting labels as a hash' do
      container = @compose.get_containers_by(label: 'busybox2').first

      # Start container
      container.start

      env = container.stats['Config']['Labels']
      expect(env['com.example.foo']).to eq('bar')

      # Stop container
      container.stop
    end

    it 'should assing given name to container' do
      container = @compose.get_containers_by(label: 'busybox2').first

      # Start container
      container.start

      container_name = container.stats['Name']
      expect(container_name).to match(/\/#{ComposeUtils.dir_name}_busybox2_\d+/)

      # Stop container
      container.stop
    end

    it 'should assing given container_name to container' do
      container = @compose.get_containers_by(label: 'busybox1').first

      # Start container
      container.start

      container_name = container.stats['Name']
      expect(container_name).to eq('/busybox-container')

      # Stop container
      container.stop
    end

    it 'should assing a random name to container when name is not given' do
      container = @compose.get_containers_by(label: 'busybox2').first

      # Start container
      container.start

      container_name = container.stats['Name']
      expect(container_name).to_not be_nil

      # Stop container
      container.stop
    end

    it 'should filter containers by its attributes' do
      expect(@compose.get_containers_by(label: 'busybox2')).to eq([@compose.containers['busybox2']])
      expect(@compose.get_containers_by(name: @compose.containers['busybox1'].attributes[:name])).to eq([@compose.containers['busybox1']])
      expect(@compose.get_containers_by_given_name('busybox2')).to eq([@compose.containers['busybox2']])
      expect(@compose.get_containers_by(name: 'busybox-container')).to eq([@compose.containers['busybox1']])
      expect(@compose.get_containers_by(image: 'busybox:latest')).to eq([
          @compose.containers['busybox1'],
          @compose.containers['busybox2'],
          @compose.containers['busybox3']
      ])
    end
  end

  context 'With memory' do
    before(:all) do
      @compose1 = DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/compose_1.yaml'), false)
      @compose1.start
      @compose2 = DockerCompose.load(File.expand_path('spec/docker-compose/fixtures/empty_compose.yml'), true)
    end

    it 'should load all running containers from this directory' do
      expect(@compose2.containers.length).to eq(@compose1.containers.length)
    end

    it '@compose2 should have the same containers of @compose1' do
      docker_containers_compose1 = @compose1.containers.values.select { |c| c.container }
      docker_containers_compose2 = @compose2.containers.values.select { |c| c.container }

      # Check that both @composes have the same containers (based on its names)
      docker_containers_compose2.each_index do |index|
        expect(docker_containers_compose2[index].attributes['Name']).to eq(docker_containers_compose1[index].attributes['Name'])
      end
    end

    it 'expect last container from @compose2 to be assigned as loaded from environment' do
      expect(@compose2.containers.values.last.loaded_from_environment?).to be true
    end

    after(:all) do
      @compose1.delete
    end
  end
end
