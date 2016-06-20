module QueueHelpers
  def test_queue(queue_name = 'test')
    queues[queue_name] ||= begin
      queue = channel.queue(Leveret.configuration.queue_name, persistent: true, auto_delete: false,
        arguments: { 'x-max-priority' => 2 })
      queue.bind(exchange, routing_key: queue_name)
      queue
    end
  end

  def queues
    @queues ||= {}
  end

  def flush_queue(queue_name = 'test')
    test_queue(queue_name).purge
  end

  # Blocks until there is a new message on the queue and then returns
  def get_message_from_queue(queue_name = 'test')
    queue = test_queue(queue_name)
    loop do
      _, _, message = queue.pop
      return message unless message.nil?
    end
  end

  private

  def exchange
    @exchange ||= channel.exchange(Leveret.configuration.exchange_name, type: :direct, durable: true,
      auto_delete: false)
  end

  def channel
    @channel ||= begin
      chan = Leveret.mq_connection.create_channel
      chan.prefetch(1)
      chan
    end
  end
end
