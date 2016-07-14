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
      def perform(params)
        new(params).perform
      end

      def queue_name(name)
        job_options[:queue_name] = name
      end

      def priority(pri)
        job_options[:priority] = pri
      end

      def job_options
        @job_options ||= {
          queue_name: Leveret.configuration.default_routing_key,
          priority: :normal
        }
      end

      def enqueue(params = {})
        payload = { job: self.name, params: params }
        queue.publish(payload, priority: job_options[:priority])
      end

      def queue
        @queue ||= Leveret::Queue.new(job_options[:queue_name])
      end
    end
  end
end
