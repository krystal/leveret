require 'spec_helper'

describe Leveret::Job do
  it "Can enqueue a job" do
    TestJob.queue(one: 1, two: 2)
  end
end
