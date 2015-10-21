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
end
