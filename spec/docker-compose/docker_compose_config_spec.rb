require 'spec_helper'

RSpec.shared_examples 'a docker config' do
  it 'should have the correct version info' do
    expect(config.version).to eq config_version
  end

  it 'should read a YAML file correctly' do
    expect(config.services.length).to eq(num_services)
  end
end

describe DockerComposeConfig do
  context 'Handles version 2 config' do
    config_file = File.expand_path('spec/docker-compose/fixtures/compose_2.yaml')

    it_behaves_like 'a docker config' do
      let(:config_version) { 2 }
      let(:num_services) { 3 }
      let(:config) { DockerComposeConfig.new(config_file) }
    end
  end

  context 'Handles version 1 config' do
    config_file = File.expand_path('spec/docker-compose/fixtures/compose_1.yaml')

    it_behaves_like 'a docker config' do
      let(:config_version) { 1 }
      let(:num_services) { 3 }
      let(:config) { DockerComposeConfig.new(config_file) }
    end
  end

  context 'Handles empty files' do
    config_file = File.expand_path('spec/docker-compose/fixtures/empty_compose.yml')

    it_behaves_like 'a docker config' do
      let(:config_version) { 1 }
      let(:num_services) { 0 }
      let(:config) { DockerComposeConfig.new(config_file) }
    end
  end
end
