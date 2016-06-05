require 'spec_helper'

describe Compose do
  context 'Initialize' do
    before(:all) do
      @compose = Compose.new
    end

    it 'should start with no containers' do
      expect(@compose.containers.empty?).to be true
    end
  end

  context 'Add containers' do
    before(:all) do
      @attributes_container1 = {
        label: 'container1',
        image: 'busybox:latest',
        command: 'ping -c 3 localhost'
      }

      @attributes_container2 = {
        label: 'container2',
        image: 'busybox:latest',
        links: ['container3'],
        command: 'ping -c 3 localhost'
      }

      @attributes_container3 = {
        label: 'container3',
        image: 'busybox:latest',
        command: 'ping -c 3 localhost'
      }

      @attributes_container_from_environment = {
        label: 'container_from_environment',
        image: 'busybox:latest',
        links: ['container3'],
        command: 'ping -c 3 localhost',
        loaded_from_environment: true
      }
    end

    context 'Without dependencies' do
      before(:all) do
        @compose = Compose.new
        @compose.add_container(ComposeContainer.new(@attributes_container1))
        @compose.add_container(ComposeContainer.new(@attributes_container3))
        @compose.link_containers
      end

      it 'should have 2 containers' do
        expect(@compose.containers.length).to eq(2)
      end

      it 'should not have dependencies between containers' do
        @compose.containers.values.each do |container|
          expect(container.dependencies.empty?).to be true
        end
      end
    end

    context 'With dependencies' do
      before(:all) do
        @compose = Compose.new
        @compose.add_container(ComposeContainer.new(@attributes_container2))
        @compose.add_container(ComposeContainer.new(@attributes_container3))
        @compose.add_container(ComposeContainer.new(@attributes_container_from_environment))
        @compose.link_containers
      end

      it 'should have 2 containers' do
        expect(@compose.containers.length).to eq(3)
      end

      it 'container2 should depend on container3' do
        container2 = @compose.containers[@attributes_container2[:label]]
        container3 = @compose.containers[@attributes_container3[:label]]

        expect(container2.dependencies.include?(container3)).to be true
        expect(container3.dependencies.empty?).to be true
      end

      it 'container loaded from environment should not have dependencies' do
        container_from_environment = @compose.containers[@attributes_container_from_environment[:label]]
        expect(container_from_environment.dependencies.empty?).to be true
      end
    end

    it 'should increment label when already exists' do
      @compose = Compose.new

      # Add the same container twice
      @compose.add_container(ComposeContainer.new(@attributes_container1))
      @compose.add_container(ComposeContainer.new(@attributes_container1))

      label_first_container  = @compose.containers.keys[0]
      label_second_container = @compose.containers.keys[1]

      expect(label_first_container).to_not eq(label_second_container)
    end
  end
end
