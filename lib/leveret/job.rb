module Leveret
  module Job
    def perform(params = {})
      raise NotImplementedError
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :job_options

      def job_options(options = {})
        @job_options = {
          queue_name: 'standard',
          priority: :normal
        }.merge(options)
      end

      def enqueue(params = {})
        payload = { job: self.name, params: params }
        queue.publish(serialize_params(payload), priority: job_options[:priority])
      end

      def queue
        @queue ||= Leveret::Queue.new(job_options[:queue_name])
      end

      def serialize_params(params)
        JSON.dump(params)
      end
    end
  end
end
