require 'spec_helper'

describe Leveret::DelayQueue do
  let(:delay_queue) { Leveret::DelayQueue.new }

  describe '#queue' do
    let(:queue) { delay_queue.queue }

    it 'should be a bunny queue' do
      expect(queue).to be_a(Bunny::Queue)
    end

    it 'should have the correct name' do
      expect(queue.name).to eq(Leveret.configuration.delay_queue_name)
    end
  end

  describe '#republish' do
    let(:delivery_info) { OpenStruct.new(delivery_tag: "delivery-tag", routing_key: "routing-key") }
    let(:properties) { OpenStruct.new(priority: 2) }
    let(:params) { Leveret::Parameters.new(key: 'value') }
    let(:message) { Leveret::Message.new(delivery_info, properties, params) }

    it 'publishes a message onto the delay exchange' do
      expect(delay_queue.send(:delay_exchange)).to receive(:publish).with(params.serialize, persistent: true,
        expiration: Leveret.configuration.delay_time, routing_key: delivery_info.routing_key,
        priority: properties.priority)
      delay_queue.republish(message)
    end
  end
end
