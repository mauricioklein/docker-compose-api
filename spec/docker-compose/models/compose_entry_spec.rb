require 'spec_helper'

describe ComposeEntry do
  context 'Object creation' do
    it 'should prepare the attributes correctly' do
      attributes = {
          'label'   => 'CONTAINER_LABEL',
          'build'   => 'BUILD',
          'image'   => 'IMAGENAME:TAGNAME',
          'expose'  => ["1000", "2000"],
          'command' => "CMD0 CMD1 CMD2"
      }

      entry = ComposeEntry.new(attributes)

      expect(entry.label).to eq('CONTAINER_LABEL')
      expect(entry.build).to eq('BUILD')
      expect(entry.baseImage).to eq('IMAGENAME')
      expect(entry.tag).to eq('TAGNAME')
      expect(entry.expose.length).to eq(2)
        expect(entry.expose.keys[0]).to eq('1000')
        expect(entry.expose.keys[1]).to eq('2000')
      expect(entry.command.length).to eq(3)
        expect(entry.command[0]).to eq('CMD0')
        expect(entry.command[1]).to eq('CMD1')
        expect(entry.command[2]).to eq('CMD2')
    end

    it 'should set tag to latest when not informed' do
      attributes = {
          'label'   => 'CONTAINER_LABEL',
          'build'   => 'BUILD',
          'image'   => 'IMAGENAME',
          'expose'  => ["1000", "2000"],
          'command' => "CMD0 CMD1 CMD2"
      }

      entry = ComposeEntry.new(attributes)

      expect(entry.tag).to eq('latest')
    end

    it 'should not break when trying to start/stop a nil container' do
      ComposeEntry.new({}).start
      ComposeEntry.new({}).stop
    end
  end
end
