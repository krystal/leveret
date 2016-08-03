module Leveret
  # Handles the acknowledgement or rejection of messages after execution
  class ResultHandler
    extend Forwardable

    attr_accessor :delivery_info, :properties, :params

    def_delegators :delivery_info, :channel, :delivery_tag
    def_delegators :Leveret, :log, :delay_queue

    # @param [Bunny::DeliveryInfo] delivery_info Contains incoming channel, queue, delivery tag etc. needed for acking
    # @param [Bunny::MessageProperties] properties Contains priority information incase we need to requeue
    # @param [Parameters] payload The job name and parameters the job requires
    def initialize(delivery_info, properties, params)
      self.delivery_info = delivery_info
      self.properties = properties
      self.params = params
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
      channel.requeue(delivery_tag, true)
    end

    # Acknowledge the message, but publish it onto the delay queue for execution later
    def delay
      log.debug ["[#{delivery_tag}] Delaying message"]
      channel.acknowledge(delivery_tag)
      delay_queue.republish(delivery_info, properties, params)
    end
  end
end
