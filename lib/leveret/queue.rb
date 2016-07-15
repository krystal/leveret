module Leveret
  class Queue
    extend Forwardable

    PRIORITY_MAP = { low: 0, normal: 1, high: 2 }.freeze

    attr_reader :name, :queue

    def_delegators :Leveret, :exchange, :channel
    def_delegators :queue, :pop, :purge

    def initialize(name = nil)
      @name = name || Leveret.configuration.default_queue_name
      @queue = connect_to_queue
    end

    def publish(payload, options = {})
      priority_id = PRIORITY_MAP[options[:priority]] || PRIORITY_MAP[:normal]

      queue.publish(serialize_payload(payload), persistent: true, routing_key: name, priority: priority_id)
    end

    def subscribe
      queue.subscribe(manual_ack: true) do |delivery_info, properties, msg|
        result = yield(delivery_info, properties, deserialize_payload(msg)) if block_given?

        if result == :ack
          channel.acknowledge(delivery_info.delivery_tag, false)
        elsif result == :reject
          channel.reject(delivery_info.delivery_tag)
        elsif result == :requeue
          channel.reject(delivery_info.delivery_tag, true)
        end
      end
    end

    private

    def serialize_payload(params)
      JSON.dump(params)
    end

    def deserialize_payload(json)
      JSON.parse(json)
    end

    def connect_to_queue
      queue = channel.queue(mq_name, persistent: true, auto_delete: false, arguments: { 'x-max-priority' => 2 })
      queue.bind(exchange, routing_key: name)
      queue
    end

    def mq_name
      @mq_name ||= [Leveret.configuration.queue_name_prefix, name].join('_')
    end
  end
end
