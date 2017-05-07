require 'spec_helper'

describe V1::Container do
  let(:definition) { ComposeFile.new(File.expand_path('spec/fixtures/compose_files/v1.yaml')) }
  let(:busybox) { definition.content.busybox1 }

  subject { described_class.new(busybox) }

  it 'bla' do
    byebug
  end
end
