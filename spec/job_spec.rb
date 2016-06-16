require 'spec_helper'

describe Leveret::Job do
  it "Can enqueue a job" do
    TestJob.enqueue(one: 1, two: 2)
  end

  it 'Can have different priorities', focus: true do
    TestJob.enqueue
    TestJob.enqueue
    HighPriorityTestJob.enqueue
  end
end
