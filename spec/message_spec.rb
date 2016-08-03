require 'spec_helper'

RSpec.describe Leveret::Message do
  let(:delivery_info) { OpenStruct.new(delivery_tag: "delivery-tag", routing_key: "routing-key") }
  let(:properties) { OpenStruct.new(priority: 2) }
  let(:params) { Leveret::Parameters.new(key: 'value') }

  let(:message) { Leveret::Message.new(delivery_info, properties, params) }

  describe '.new' do
    it 'accepts 3 arguments' do
      msg = Leveret::Message.new(delivery_info, properties, params)
      expect(msg).to be_a(Leveret::Message)
    end
  end

  describe '#delivery_tag' do
    it 'returns the delivery tag from the delivery_info' do
      expect(message.delivery_tag).to eq(delivery_info.delivery_tag)
    end
  end

  describe '#routing_key' do
    it 'returns the routing key from the delivery info' do
      expect(message.routing_key).to eq(delivery_info.routing_key)
    end
  end

  describe '#priority' do
    it 'returns the priority from properties' do
      expect(message.priority).to eq(properties.priority)
    end
  end
end
