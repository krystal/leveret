module Leveret
  module Job
    attr_accessor :params

    def initialize(params = {})
      self.params = params
    end

    def perform
      raise NotImplementedError
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def perform(serialized_params)
        params = deserialize_params(serialized_params)
        new(params).perform
      end

      def set_job_options(opts = {})
        @job_options = job_options.merge(opts)
      end

      def job_options
        @job_options ||= {
          queue_name: Leveret.configuration.default_routing_key,
          priority: :normal
        }
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

      def deserialize_params(json)
        JSON.parse(json)
      end
    end
  end
end
