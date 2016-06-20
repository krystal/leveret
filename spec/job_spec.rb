require 'spec_helper'

describe Leveret::Job do
  it "Can enqueue a job" do
    params = { one: 1, two: 2 }
    payload = JSON.dump(job: "TestJob", params: params)

    expect(TestJob.queue).to receive(:publish).with(payload, priority: :normal)
    TestJob.enqueue(one: 1, two: 2)
  end

  it 'Can have different priorities', focus: true do
    expect(TestJob.queue).to receive(:publish).with(anything, priority: :normal)
    expect(HighPriorityTestJob.queue).to receive(:publish).with(anything, priority: :high)

    TestJob.enqueue
    HighPriorityTestJob.enqueue
  end
end
