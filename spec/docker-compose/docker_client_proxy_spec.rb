require 'spec_helper'

describe DockerClientProxy do
  let(:image_mock) { double(:docker_imahe) }
  let(:container_mock) { double(:docker_container) }

  describe '#pull_image' do
    subject { DockerClientProxy.instance.pull_image(image) }

    let(:image) { 'foobar' }

    before do
      allow(Docker::Image).to receive(:create).with('fromImage' => image).and_return(image_mock)
    end

    it { is_expected.to eq(image_mock) }
  end

  describe '#build_image' do
    subject { DockerClientProxy.instance.build_image(image_description) }

    let(:image_description) { 'cmd: "ps aux"' }

    before do
      allow(Docker::Image).to receive(:build).with(image_description).and_return(image_mock)
    end

    it { is_expected.to eq(image_mock) }
  end

  describe '#create_container' do
    subject { DockerClientProxy.instance.create_container(attributes) }

    let(:attributes) { { foo: 'bar' } }

    before do
      allow(Docker::Container).to receive(:create).with(attributes).and_return(container_mock)
    end

    it { is_expected.to eq(container_mock) }
  end
end
