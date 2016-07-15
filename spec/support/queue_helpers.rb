module QueueHelpers
  extend Forwardable

  def_delegators :Leveret, :exchange, :channel
  def_delegators :channel, :wait_for_confirms

  def test_queue(queue_name = 'test')
    queues[queue_name] ||= Leveret::Queue.new(queue_name)
  end

  def queues
    @queues ||= {}
  end

  def flush_queue(queue_name = 'test')
    test_queue(queue_name).purge
  end

  # Blocks until there is a new message on the queue and then returns
  def get_message_from_queue(queue_name = 'test', block_until_message = true)
    queue = test_queue(queue_name)
    loop do
      _, _, message = queue.pop
      if message.nil?
        return unless block_until_message
      else
        return JSON.parse(message)
      end
    end
  end
end
