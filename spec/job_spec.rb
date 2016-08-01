require 'spec_helper'

describe Leveret::Job do
  let(:default_queue_name) { Leveret.configuration.default_queue_name }
  let(:default_priority) { :normal }

  context ".enqueue" do
    it 'can be called without params' do
      expect(TestJob.queue).to receive(:publish).with({ job: "TestJob", params: {} }, priority: default_priority)
      TestJob.enqueue
    end

    it 'can be called with params' do
      params = { one: 1, two: 2 }

      expect(TestJob.queue).to receive(:publish).with({ job: "TestJob", params: params }, priority: default_priority)
      TestJob.enqueue(one: 1, two: 2)
    end

    it 'can override the priority of the parent class' do
      new_priority = :low

      expect(TestJob.queue).to receive(:publish).with({ job: "TestJob", params: {} }, priority: new_priority)
      TestJob.enqueue(priority: new_priority)
    end

    it 'can override the queue name of the parent class' do
      new_queue = :other
      queue = TestJob.queue(new_queue)

      expect(queue).to receive(:publish).with({ job: "TestJob", params: {} }, anything)
      TestJob.enqueue(queue_name: new_queue)
    end
  end

  context '.queue_name' do
    it 'defaults to the configured default' do
      expect(DefaultQueueTestJob.job_options[:queue_name]).to eq(default_queue_name)
      expect(DefaultQueueTestJob.queue.name).to eq(default_queue_name)
    end

    it 'can be set to another queue' do
      expect(TestJob.job_options[:queue_name]).to eq('test')
      expect(TestJob.queue.name).to eq('test')
    end
  end

  context '.priority', focus: true do
    it 'defaults to :normal priority' do
      expect(TestJob.job_options[:priority]).to eq(default_priority)
      expect(TestJob.queue).to receive(:publish).with(anything, priority: default_priority)
      TestJob.enqueue
    end

    it 'can be set to high' do
      expect(HighPriorityTestJob.job_options[:priority]).to eq(:high)
      expect(HighPriorityTestJob.queue).to receive(:publish).with(anything, priority: :high)
      HighPriorityTestJob.enqueue
    end

    it 'can be set to low' do
      expect(LowPriorityTestJob.job_options[:priority]).to eq(:low)
      expect(LowPriorityTestJob.queue).to receive(:publish).with(anything, priority: :low)
      LowPriorityTestJob.enqueue
    end
  end

  context '.job_options' do
    it 'returns default configuration options' do
      expect(DefaultQueueTestJob.job_options).to eq(priority: default_priority, queue_name: default_queue_name)
    end

    it 'returns configured options' do
      expect(HighPriorityTestJob.job_options).to eq(priority: :high, queue_name: 'test')
    end
  end

  context '.perform' do
    it 'returns :success for a completed job' do
      expect(TestJob.perform).to eq(:success)
    end

    it 'returns :requeue for a job that must go back in the queue' do
      expect(RequeueTestJob.perform).to eq(:requeue)
    end

    it 'returns :reject for a job that will not complete' do
      expect(RejectTestJob.perform).to eq(:reject)
    end

    it 'calls an error handler when the job throws an exception' do
      expect(Leveret.configuration.error_handler).to receive(:call).with(StandardError, instance_of(ExceptionJob))
      ExceptionJob.perform
    end

    it 'rejects the message when the job throws an exception' do
      expect(ExceptionJob.perform).to eq(:reject)
    end
  end
end
