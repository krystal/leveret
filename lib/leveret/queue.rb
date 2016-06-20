module Leveret
  class Queue
    PRIORITY_MAP = { low: 0, normal: 1, high: 2 }.freeze

    attr_accessor :name

    def initialize(name = nil)
      self.name = name || 'standard'
    end

    def publish(payload, options = {})
      priority_id = PRIORITY_MAP[options[:priority]] || PRIORITY_MAP[:normal]

      exchange.publish(payload, persistent: true, routing_key: name, priority: priority_id)
    end

    def subscribe
      queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, msg|
        yield(channel, delivery_info, properties, msg) if block_given?
        channel.acknowledge(delivery_info.delivery_tag, false)
      end
    end

    private

    def queue
      @queue ||= begin
        queue = channel.queue(Leveret.configuration.queue_name, persistent: true, auto_delete: false,
          arguments: { 'x-max-priority' => 2 })
        queue.bind(exchange, routing_key: name)
        queue
      end
    end

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
end
