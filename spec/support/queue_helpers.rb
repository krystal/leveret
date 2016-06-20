module QueueHelpers
  def test_queue(queue_name = 'test')
    @queue ||= {}
    @queue[queue_name] ||= begin
      queue = channel.queue(Leveret.configuration.queue_name, persistent: true, auto_delete: false,
        arguments: { 'x-max-priority' => 2 })
      queue.bind(exchange, routing_key: queue_name)
      queue
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
