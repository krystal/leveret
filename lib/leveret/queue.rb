module Leveret
  class Queue
    extend Forwardable

    PRIORITY_MAP = { low: 0, normal: 1, high: 2 }.freeze

    attr_reader :name, :queue

    def_delegators :Leveret, :exchange, :channel, :log
    def_delegators :queue, :pop, :purge

    def initialize(name = nil)
      @name = name || Leveret.configuration.default_queue_name
      @queue = connect_to_queue
    end

    def publish(payload, options = {})
      priority_id = PRIORITY_MAP[options[:priority]] || PRIORITY_MAP[:normal]
      payload = serialize_payload(payload)

      log.debug "Publishing #{payload.inspect} for queue #{name} (Priority: #{priority_id})"
      queue.publish(payload, persistent: true, routing_key: name, priority: priority_id)
    end

    def subscribe
      log.info "Subscribing to #{name}"
      queue.subscribe(manual_ack: true) do |delivery_info, _properties, msg|
        log.debug "Received #{msg} from #{name}"
        yield(delivery_info.delivery_tag, deserialize_payload(msg))
      end
    end

    private

    def serialize_payload(params)
      Leveret::Parameters.new(params).serialize
    end

    def deserialize_payload(json)
      Leveret::Parameters.from_json(json)
    end

    def connect_to_queue
      queue = channel.queue(mq_name, durable: true, auto_delete: false, arguments: { 'x-max-priority' => 2 })
      queue.bind(exchange, routing_key: name)
      log.debug "Connected to #{mq_name}, bound on #{name}"
      queue
    end

    def mq_name
      @mq_name ||= [Leveret.configuration.queue_name_prefix, name].join('_')
    end
  end
end
