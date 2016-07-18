require 'spec_helper'

describe Leveret::Queue do
  let(:queue) { Leveret::Queue.new('test') }

  it 'has a name' do
    expect(queue.name).to eq('test')
  end

  it 'can publish a payload onto a queue' do
    payload = { 'data' => "Test Payload" }
    queue.publish(payload)

    # Pop the data off of the queue
    rtn_payload = get_message_from_queue
    expect(rtn_payload).to eq(payload)
  end

  it 'can prioritise message delivery' do
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

  it "won't pick up another queues jobs" do
    other_queue = Leveret::Queue.new('other_test')
    payload = { 'data' => 'wotcha' }
    other_queue.publish(payload)

    # Sleep to ensure everything is on the queue
    sleep(0.5)

    rtn = get_message_from_queue(queue.name, false)
    expect(rtn).to be_nil

    rtn = get_message_from_queue(other_queue.name, false)
    expect(rtn).to eq(payload)
  end

  it 'can be subscribed to and call a block when a message is received' do
    payload = { 'uniq' => SecureRandom.base64 }
    expect do |b|
      consumer = queue.subscribe(&b)
      queue.publish(payload)
      sleep(0.5)
      consumer.cancel
    end.to yield_with_args(payload)
  end
end
