require 'spec_helper'

describe ComposeEntry do
  it 'should prepare the attributes correctly' do
    attributes = {
        'id' => 'CONTAINER_ID',
        'build' => 'BUILD',
        'image' => 'IMAGENAME:TAGNAME',
        'ports' => ["1000:1000", "2000:2000"],
        'command' => "CMD0 CMD1 CMD2"
    }

    entry = ComposeEntry.new(attributes)

    expect(entry.id).to eq('CONTAINER_ID')
    expect(entry.build).to eq('BUILD')
    expect(entry.baseImage).to eq('IMAGENAME')
    expect(entry.tag).to eq('TAGNAME')
    expect(entry.ports.length).to eq(2)
      expect(entry.ports['1000']).to eq('1000')
      expect(entry.ports['2000']).to eq('2000')
    expect(entry.command.length).to eq(3)
      expect(entry.command[0]).to eq('CMD0')
      expect(entry.command[1]).to eq('CMD1')
      expect(entry.command[2]).to eq('CMD2')
  end
end
