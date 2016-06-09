module Leveret
  module Job
    def perform(params = {})
      raise NotImplementedError
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :queue_name, :queue_options

      def on_queue(name, opts = {})
        @queue_name = name
        @queue_options = { priority: 0 }.merge(opts)
      end

      def queue(params = {})
        payload = { job: self.name, params: params }
        Leveret.mq_exchange.publish(serialize_params(payload), persistent: true, routing_key: queue_name,
          priority: queue_options[:priority])
      end

      def serialize_params(params)
        JSON.dump(params)
      end
    end
  end
end
