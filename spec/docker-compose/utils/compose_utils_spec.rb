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
end
