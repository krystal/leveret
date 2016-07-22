module Leveret
  # Include this module in your job to create a leveret compatible job.
  # Once included, simply override #perform to do your jobs action.
  #
  # To set a different queue name call #queue_name in your class, to set
  # the default priority call #priority in your class.
  #
  # To queue a job simply call #enqueue on the class with the parameters
  # to be passed. These params will be serialized as JSON in the interim,
  # so ensure that your params are json-safe.
  module Job
    # Raise this when your job has failed, but try again when a worker is
    # available again.
    class RequeueJob < StandardError; end

    # Raise this when your job has failed, but you don't want to requeue it
    # and try again.
    class RejectJob < StandardError; end

    # Instance methods to mixin with your job
    module InstanceMethods
      attr_accessor :params

      def initialize(params = {})
        self.params = params
      end

      def perform
        raise NotImplementedError
      end
    end

    # Class methods to mixin with your job
    module ClassMethods
      def perform(params = {})
        log.info "Running #{name} with #{params.to_s}"
        new(params).perform
        :success
      rescue Leveret::Job::RequeueJob
        log.info "Requeueing job #{name} with #{params}"
        :requeue
      rescue Leveret::Job::RejectJob
        log.info "Rejecting job #{name} with #{params}"
        :reject
      rescue StandardError => e
        Leveret.log.error "#{e.message} when processing #{name} with #{params}"
        Leveret.configuration.error_handler.call(e)
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
        q_name = params.delete(:queue_name) || job_options[:queue_name]

        Leveret.log.info "Queuing #{name} to #{q_name} (#{priority}) with #{params}"

        payload = { job: self.name, params: params }
        queue(q_name).publish(payload, priority: priority)
      end

      def queue(q_name = nil)
        q_name ||= job_options[:queue_name]
        @queue ||= {}
        @queue[q_name] ||= Leveret::Queue.new(q_name)
      end

      def log
        Leveret.log
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end
  end
end
