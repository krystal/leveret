module Leveret
  # Connects to a special queue which keeps messages in a holding pattern until a timeout expires and then
  # publishes those messages back to the main queue for processing.
  class DelayQueue
    extend Forwardable

    attr_reader :queue

    def_delegators :Leveret, :configuration, :channel, :log

    def initialize
      @queue = connect_to_queue
    end

    # Place a message onto the delay queue, which will later be expired and sent back to the main exchange
    def republish(delivery_info, properties, params)
      delay_exchange.publish(params.serialize, expiration: configuration.delay_time, persistent: true,
        routing_key: delivery_info.routing_key, priority: properties.priority)
    end

    private

    def connect_to_queue
      queue = channel.queue(configuration.delay_queue_name, durable: true,
        arguments: { 'x-dead-letter-exchange': configuration.exchange_name })
      queue.bind(delay_exchange)
      log.info "Connected to #{configuration.delay_queue_name}, bound to #{configuration.delay_exchange_name}"
      queue
    end

    def delay_exchange
      @delay_exchange ||= channel.exchange(Leveret.configuration.delay_exchange_name, type: :fanout, durable: :true)
    end
  end
end
