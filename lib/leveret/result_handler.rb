module Leveret
  # Handles the acknowledgement or rejection of messages after execution
  class ResultHandler
    extend Forwardable

    attr_accessor :incoming_message

    def_delegators :Leveret, :log, :delay_queue

    # @param [Message] incoming_message Contains delivery information such as the delivery_tag
    def initialize(incoming_message)
      self.incoming_message = incoming_message
    end

    # Call the appropriate handling method for the result
    #
    # @param [Symbol] result Result returned from running the job, one of +:success+, +:reject+ or +:requeue+
    def handle(result)
      log.info "[#{delivery_tag}] Job returned #{result}"
      send(result) if [:success, :reject, :requeue, :delay].include?(result)
    end

    # Mark the message as acknowledged
    def success
      log.debug "[#{delivery_tag}] Acknowledging message"
      channel.acknowledge(delivery_tag)
    end

    # Mark the message as rejected (failure)
    def reject
      log.debug "[#{delivery_tag}] Rejecting message"
      channel.reject(delivery_tag)
    end

    # Reject the message and reinsert it onto it's queue
    def requeue
      log.debug "[#{delivery_tag}] Requeueing message"
      channel.reject(delivery_tag, true)
    end

    # Acknowledge the message, but publish it onto the delay queue for execution later
    def delay
      log.debug ["[#{delivery_tag}] Delaying message"]
      channel.acknowledge(delivery_tag)
      delay_queue.republish(incoming_message)
    end

    private

    def channel
      incoming_message.delivery_info.channel
    end

    def delivery_tag
      incoming_message.delivery_info.delivery_tag
    end
  end
end
