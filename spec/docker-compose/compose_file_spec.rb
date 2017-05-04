require 'spec_helper'

describe ComposeFile do
  subject { described_class.new(file) }

  describe 'given valid YAML file' do
    context 'with V1' do
      let(:file) { File.expand_path('spec/fixtures/compose_files/v1.yaml') }

      it { expect(subject.content).to_not be_nil }
      it { expect(subject.version).to eq(1) }
    end

    context 'with V2' do
      let(:file) { File.expand_path('spec/fixtures/compose_files/v2.yaml') }

      it { expect(subject.content).to_not be_nil }
      it { expect(subject.version).to eq(2) }
    end
  end

  describe 'given invalid YAML file' do
    context 'with nil file' do
      let(:file) { nil }

      it { expect { subject }.to raise_exception(ComposeFileLoadException) }
    end

    context 'with unexistente file' do
      let(:file) { 'foobar' }

      it { expect { subject }.to raise_exception(ComposeFileLoadException) }
    end
  end
end
