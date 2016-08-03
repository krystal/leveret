require 'spec_helper'

describe Leveret::ResultHandler do
  let(:channel) { double('channel') }
  let(:delivery_info) do
    OpenStruct.new(delivery_tag: "delivery-tag", routing_key: "routing-key", channel: channel)
  end
  let(:properties) { OpenStruct.new(priority: 2) }
  let(:params) { Leveret::Parameters.new(key: 'value') }
  let(:message) { Leveret::Message.new(delivery_info, properties, params) }

  let(:handler) { Leveret::ResultHandler.new(message) }

  describe '.new' do
    it 'takes a message' do
      result_handler = Leveret::ResultHandler.new(message)
      expect(result_handler).to be_a(Leveret::ResultHandler)
    end
  end

  describe '#handle' do
    it 'directs a :success message to #success' do
      expect(handler).to receive(:success)
      handler.handle(:success)
    end
    it 'directs a :reject message to #reject' do
      expect(handler).to receive(:reject)
      handler.handle(:reject)
    end
    it 'directs a :requeue message to #requeue' do
      expect(handler).to receive(:requeue)
      handler.handle(:requeue)
    end
    it 'directs a :delay message to #delay' do
      expect(handler).to receive(:delay)
      handler.handle(:delay)
    end
  end

  describe '#success' do
    it 'calls ack on the channel' do
      expect(channel).to receive(:acknowledge).with(delivery_info.delivery_tag)
      handler.success
    end
  end

  describe '#reject' do
    it 'calls reject on the channel' do
      expect(channel).to receive(:reject).with(delivery_info.delivery_tag)
      handler.reject
    end
  end

  describe '#requeue' do
    it 'calls reject with the requeue argument' do
      expect(channel).to receive(:reject).with(delivery_info.delivery_tag, true)
      handler.requeue
    end
  end

  describe '#delay' do
    it 'calls ack on the channel and publishes to the delay queue' do
      expect(channel).to receive(:acknowledge).with(delivery_info.delivery_tag)
      expect(Leveret.delay_queue).to receive(:republish).with(message)

      handler.delay
    end
  end
end
