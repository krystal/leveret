module Leveret
  module Job
    def perform(params = {})
      raise NotImplementedError
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :options

      def job_options(opts = {})
        @options = {
          queue_name: 'standard',
          priority: :normal
        }.merge(opts)
      end

      def enqueue(params = {})
        payload = { job: self.name, params: params }
        queue.publish(serialize_params(payload), priority: options[:priority])
      end

      def queue
        @queue ||= Leveret::Queue.new(options[:queue_name])
      end

      def serialize_params(params)
        JSON.dump(params)
      end
    end
  end
end
