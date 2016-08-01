require 'spec_helper'

describe Leveret::Worker do
  describe '.new' do
    it 'uses the default queue if none is specified' do
      worker = Leveret::Worker.new
      expect(worker.queues.map(&:name)).to eq([Leveret.configuration.default_queue_name])
    end

    it 'can use custom queue names' do
      queue_names = %w(test other)

      worker = Leveret::Worker.new(*queue_names)
      expect(worker.queues.map(&:name)).to eq(queue_names)
    end
  end
end
