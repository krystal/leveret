require 'spec_helper'

describe Leveret::Queue do
  let(:queue) { Leveret::Queue.new('test') }

  describe '#name' do
    it { expect(queue.name).to eq('test') }
  end

  describe '#queue' do
    it "should be a bunny queue" do
      expect(queue.queue).to be_a(Bunny::Queue)
    end

    it "should be durable" do
      expect(queue.queue.durable?).to be true
    end
  end

  describe '#publish' do
    it 'pushes a message onto the exchange' do
      payload = { 'test' => 'data' }
      serialized_payload = JSON.dump(payload)

      expect(queue.queue).to receive(:publish).with(serialized_payload, hash_including(routing_key: 'test'))
      queue.publish(payload)
    end

    context 'can prioritise message delivery' do
      it 'sends the correct priority int for high priority' do
        expect(queue.queue).to receive(:publish).with(anything, hash_including(priority: 2))
        queue.publish({}, priority: :high)
      end

      it 'sends the correct priority int for normal priority' do
        expect(queue.queue).to receive(:publish).with(anything, hash_including(priority: 1))
        queue.publish({}, priority: :normal)
      end

      it 'sends the correct priority int for low priority' do
        expect(queue.queue).to receive(:publish).with(anything, hash_including(priority: 0))
        queue.publish({}, priority: :low)
      end

      it 'defaults to normal priority delivery' do
        expect(queue.queue).to receive(:publish).with(anything, hash_including(priority: 1))
        queue.publish({})
      end
    end
  end

  describe '#subscribe' do
    it 'calls a block when a message is received' do
      payload = { 'uniq' => SecureRandom.base64 }
      expect do |b|
        consumer = queue.subscribe(&b)
        queue.publish(payload)
        sleep(0.5)
        consumer.cancel
      end.to yield_with_args(instance_of(Bunny::DeliveryInfo), instance_of(Bunny::MessageProperties), payload)
    end

    it 'only gets called for messages placed on this queue' do
      other_queue = Leveret::Queue.new('other')
      payload = { 'data' => 'wotcha' }

      expect do |b|
        consumer = queue.subscribe(&b)
        other_queue.publish(payload)
        sleep(0.5)
        consumer.cancel
      end.not_to yield_with_args(payload)
    end
  end

  it 'receives prioritised messages in the correct order' do
    high_priority_payload = { 'data' => "High priority payload" }
    normal_priority_payload = { 'data' => "Normal priority payload" }
    low_priority_payload = { 'data' => "Low priority payload" }

    # Push messages onto the queue out of order
    queue.publish(low_priority_payload, priority: :low)
    queue.publish(high_priority_payload, priority: :high)
    queue.publish(normal_priority_payload, priority: :normal)

    # Ensure everything is on the queue
    sleep 0.5

    # As we pop messages off the queue, they should be in the order high, normal, low
    first_payload = get_message_from_queue
    second_payload = get_message_from_queue
    third_payload = get_message_from_queue

    expect(first_payload).to eq(high_priority_payload)
    expect(second_payload).to eq(normal_priority_payload)
    expect(third_payload).to eq(low_priority_payload)
  end
end
