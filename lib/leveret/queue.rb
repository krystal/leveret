module Leveret
  # Facilitates the publishing or subscribing of messages to the message queue.
  #
  # @!attribute [r] name
  #   @return [String] Name of the queue. This will have Leveret.queue_name_prefix prepended to it when creating a
  #     corresponding queue in RabbitMQ.
  # @!attribute [r] queue
  #   @return [Bunny::Queue] The backend RabbitMQ queue
  #   @see http://reference.rubybunny.info/Bunny/Queue.html Bunny::Queue Documentation
  class Queue
    extend Forwardable

    # Map the symbol names for priorities to the integers that RabbitMQ requires.
    PRIORITY_MAP = { low: 0, normal: 1, high: 2 }.freeze
    attr_reader :name, :queue

    def_delegators :Leveret, :exchange, :channel, :log
    def_delegators :queue, :pop, :purge

    # Create a new queue with the name given in the params, if no name is given it will default to
    # {Configuration#default_queue_name}. On instantiation constructor will immedaitely connect to
    # RabbitMQ backend and create a queue with the appropriate name, or join an existing one.
    #
    # @param [String] name Name of the queue to connect to.
    def initialize(name = nil)
      @name = name || Leveret.configuration.default_queue_name
      @queue = connect_to_queue
    end

    # Publish a mesage onto the queue. Fire and forget, this method is non-blocking and will not wait until
    # the message is definitely on the queue.
    #
    # @param [Hash] payload The data we wish to send onto the queue, this will be serialized and automatically
    #   deserialized when received by a {#subscribe} block.
    # @option options [Symbol] :priority (:normal) The priority this message should be treated with on the queue
    #   see {PRIORITY_MAP} for available options.
    #
    # @return [void]
    def publish(payload, options = {})
      priority_id = PRIORITY_MAP[options[:priority]] || PRIORITY_MAP[:normal]
      payload = serialize_payload(payload)

      log.debug "Publishing #{payload.inspect} for queue #{name} (Priority: #{priority_id})"
      queue.publish(payload, persistent: true, routing_key: name, priority: priority_id)
    end

    # Subscribe to this queue and yield a block for every message received. This method does not block, receiving and
    # dispatching of messages will be handled in a separate thread.
    #
    # The receiving block is responsible for acknowledging or rejecting the message. This must be done using the
    # same channel the message was received # on, {#Leveret.channel}. {Worker#ack_message} provides an example
    # implementation of this acknowledgement.
    #
    # @note The receiving block is responsible for acking/rejecting the message. Please see the note for more details.
    #
    # @yieldparam delivery_tag [String] The identifier for this message that must be used do ack/reject the message
    # @yieldparam payload [Parameters] A deserialized version of the payload contained in the message
    #
    # @return [void]
    def subscribe
      log.info "Subscribing to #{name}"
      queue.subscribe(manual_ack: true) do |delivery_info, _properties, msg|
        log.debug "Received #{msg} from #{name}"
        yield(delivery_info.delivery_tag, deserialize_payload(msg))
      end
    end

    private

    # Convert a set of parameters passed into a serialized form suitable for transport on the message queue
    #
    # @param [Hash] Paramets to be serialized
    #
    # @return [String] Encoded params ready to be sent onto the queue
    def serialize_payload(params)
      Leveret::Parameters.new(params).serialize
    end

    # Convert a set of serialized parameters into a {Parameters} object
    #
    # @param [String] JSON representation of the parameters
    #
    # @return [Parameters] Useful object representation of the parameters
    def deserialize_payload(json)
      Leveret::Parameters.from_json(json)
    end

    # Create or return a representation of the queue on the RabbitMQ backend
    #
    # @return [Bunny::Queue] RabbitMQ queue
    def connect_to_queue
      queue = channel.queue(mq_name, durable: true, auto_delete: false, arguments: { 'x-max-priority' => 2 })
      queue.bind(exchange, routing_key: name)
      log.debug "Connected to #{mq_name}, bound on #{name}"
      queue
    end

    # Calculate the name of the queue that should be used on the RabbitMQ backend
    #
    # @return [String] Backend queue name
    def mq_name
      @mq_name ||= [Leveret.configuration.queue_name_prefix, name].join('_')
    end
  end
end
