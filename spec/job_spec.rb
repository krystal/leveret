require 'spec_helper'

describe Leveret::Job do
  it "Can enqueue a job" do
    params = { one: 1, two: 2 }
    payload = JSON.dump(job: "TestJob", params: params)

    expect(TestJob.queue).to receive(:publish).with(payload, priority: :normal)
    TestJob.enqueue(one: 1, two: 2)
  end

  it 'Can have different priorities', focus: true do
    TestJob.enqueue
    HighPriorityTestJob.enqueue

    # Get two items off of the queue, the first one back should be the high priority job
    _, _, first_payload = test_queue.pop
    _, _, second_payload = test_queue.pop

    expect(JSON.parse(first_payload)['job']).to eq('HighPriorityTestJob')
    expect(JSON.parse(second_payload)['job']).to eq('TestJob')
  end
end
