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

      def enqueue(params = {})
        payload = { job: self.name, params: params }
        queue.publish(serialize_params(payload), priority: queue_options[:priority])
      end

      def queue
        @queue ||= Leveret::Queue.new(queue_name)
      end

      def serialize_params(params)
        JSON.dump(params)
      end
    end
  end
end
