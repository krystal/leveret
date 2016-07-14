module Leveret
  class Queue
    extend Forwardable

    PRIORITY_MAP = { low: 0, normal: 1, high: 2 }.freeze

    attr_accessor :name

    def_delegators :Leveret, :exchange, :channel

    def initialize(name = nil)
      self.name = name || Leveret.configuration.default_routing_key
    end

    def publish(payload, options = {})
      priority_id = PRIORITY_MAP[options[:priority]] || PRIORITY_MAP[:normal]

      exchange.publish(serialize_payload(payload), persistent: true, routing_key: name, priority: priority_id)
    end

    def subscribe
      queue.subscribe(manual_ack: true) do |delivery_info, properties, msg|
        yield(delivery_info, properties, deserialize_payload(msg)) if block_given?
        channel.acknowledge(delivery_info.delivery_tag, false)
      end
    end

    private

    def serialize_payload(params)
      JSON.dump(params)
    end

    def deserialize_payload(json)
      JSON.parse(json)
    end

    def queue
      @queue ||= begin
        queue = channel.queue(Leveret.configuration.queue_name, persistent: true, auto_delete: false,
          arguments: { 'x-max-priority' => 2 })
        queue.bind(exchange, routing_key: name)
        queue
      end
    end
  end
end
