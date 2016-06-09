require 'spec_helper'

describe ComposeUtils do
  context 'Format image' do
    it 'should return nil when image is nil' do
      expect(ComposeUtils.format_image(nil)).to be_nil
    end

    it 'should assign latest tag when no tag is provided' do
      expect(ComposeUtils.format_image('ubuntu')).to eq('ubuntu:latest')
    end

    it 'should assign base image and tag when both are provided' do
      expect(ComposeUtils.format_image('ubuntu:11')).to eq('ubuntu:11')
    end
  end

  context 'Format command' do
    it 'should return nil when command is nil' do
      expect(ComposeUtils.format_command(nil)).to be_nil
    end

    it 'should return original command as array when command has no whitespaces' do
      expect(ComposeUtils.format_command('top')).to eq(['top'])
    end

    it 'should split command in array on whitespaces' do
      expect(ComposeUtils.format_command('ls -lh')).to eq(['ls', '-lh'])
    end
  end

  context 'Format port' do
    it 'should recognize pattern "[container port]"' do
      compose_port = ComposeUtils.format_port('8080')
      expect(compose_port.container_port).to eq('8080')
      expect(compose_port.host_port).to eq(nil)
      expect(compose_port.host_ip).to eq(nil)
    end

    it 'should recognize pattern "[host port]:[container port]"' do
      compose_port = ComposeUtils.format_port('8080:7777')
      expect(compose_port.container_port).to eq('7777')
      expect(compose_port.host_port).to eq('8080')
      expect(compose_port.host_ip).to eq(nil)
    end

    it 'should recognize pattern "[host ip]:[host port]:[container port]' do
      compose_port = ComposeUtils.format_port('127.0.0.1:8080:7777')
      expect(compose_port.container_port).to eq('7777')
      expect(compose_port.host_port).to eq('8080')
      expect(compose_port.host_ip).to eq('127.0.0.1')
    end
  end

  context 'Format ports from running containers' do
    context 'filled port attributes' do
      let(:hash_attr) {
        {
          '8000/tcp' => [{
            'HostIp' => '0.0.0.0',
            'HostPort' => '4444'
          }]
        }
      }
      let(:expected_format) { ['8000:0.0.0.0:4444'] }

      it 'should format ports correctly' do
        expect(ComposeUtils.format_ports_from_running_container(hash_attr)).to eq(expected_format)
      end
    end

    context 'port without value' do
      let(:hash_attr) { {'8000/tcp' => nil} }
      let(:expected_format) { ['8000::'] }

      it 'should format ports correctly' do
        expect(ComposeUtils.format_ports_from_running_container(hash_attr)).to eq(expected_format)
      end
    end

    context 'nil port' do
      it 'should return an empty array when ports are nil' do
        expect(ComposeUtils.format_ports_from_running_container(nil)).to eq([])
      end
    end
  end

  context 'Format links' do
    it 'should recognize pattern "[service]"' do
      links = ComposeUtils.format_links(['service'])
      expect(links.key?('service')).to be true
      expect(links['service']).to eq('service')
    end

    it 'should recognize pattern "[service:label]"' do
      links = ComposeUtils.format_links(['service:label'])
      expect(links.key?('service')).to be true
      expect(links['service']).to eq('label')
    end
  end

  context 'Generate container name' do
    before(:all) do
      @name = 'foo'
      @label = 'bar'
    end

    it 'should generate name with given name' do
      name = ComposeUtils.generate_container_name(@name, @label)
      expect(name).to match(/#{ComposeUtils.dir_name}_#{@name}_\d+/)
    end

    it 'should generate name with label' do
      name = ComposeUtils.generate_container_name(nil, @label)
      expect(name).to match(/#{ComposeUtils.dir_name}_#{@label}_\d+/)
    end
  end
end
