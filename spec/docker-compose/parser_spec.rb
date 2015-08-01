require 'spec_helper'

describe DockerCompose::Parser do
  it 'should read a YAML file correctly' do
    DockerCompose::Parser.load(File.expand_path('spec/docker-compose/fixtures/sample1.yaml'))
  end
end
