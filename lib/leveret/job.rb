module Leveret
  module Job
    def perform(params = {})
      raise NotImplementedError
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :queue_name

      def on_queue(queue_name)
        @queue_name = queue_name
      end

      def queue(params = {})
        payload = { job: self.name, params: params }
        Leveret.mq_exchange.publish(serialize_params(payload), routing_key: queue_name, persistent: true)
      end

      def serialize_params(params)
        JSON.dump(params)
      end
    end
  end
end
