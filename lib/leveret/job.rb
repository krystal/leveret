module Leveret
  module Job
    class Requeue < StandardError; end
    class Reject < StandardError; end

    module InstanceMethods
      attr_accessor :params

      def initialize(params = {})
        self.params = params
      end

      def perform
        raise NotImplementedError
      end
    end

    module ClassMethods
      def perform(params)
        new(params).perform
        :success
      rescue Leveret::Job::Requeue
        :requeue
      rescue Leveret::Job::Reject
        :reject
      end

      def queue_name(name)
        job_options[:queue_name] = name
      end

      def priority(pri)
        job_options[:priority] = pri
      end

      def job_options
        @job_options ||= {
          queue_name: Leveret.configuration.default_queue_name,
          priority: :normal
        }
      end

      def enqueue(params = {})
        priority = params.delete(:priority) || job_options[:priority]

        payload = { job: self.name, params: params }
        queue.publish(payload, priority: priority)
      end

      def queue
        @queue ||= Leveret::Queue.new(job_options[:queue_name])
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end
  end
end
