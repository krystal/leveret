require 'spec_helper'

describe Leveret::Worker do
  describe '.new' do
    it 'can override the default worker concurrency count' do
      current_value = Leveret.configuration.concurrent_fork_count
      new_value = 2

      _worker = Leveret::Worker.new(concurrent_fork_count: new_value)
      expect(Leveret.configuration.concurrent_fork_count).to eq(new_value)

      Leveret.configuration.concurrent_fork_count = current_value
    end

    it 'uses the default queue if none is specified' do
      worker = Leveret::Worker.new
      expect(worker.queues.map(&:name)).to eq([Leveret.configuration.default_queue_name])
    end

    it 'can use custom queue names' do
      queue_names = %w(test other)

      worker = Leveret::Worker.new(queues: queue_names)
      expect(worker.queues.map(&:name)).to eq(queue_names)
    end
  end
end
