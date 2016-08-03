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
  #
  # @example Job Class
  #   class MyJob
  #     include Leveret::Job
  #
  #     queue_name 'my_custom_queue' # omit for default
  #     priority :high # omit for default
  #
  #     def perform
  #       File.open('/tmp/leveret-test-file.txt', 'a+') do |f|
  #         f.puts params[:test_text]
  #       end
  #
  #       sleep 5 # Job takes a long time
  #     end
  #   end
  #
  # @example Queueing a Job
  #   # With options defined in class
  #   MyJob.enqueue(test_text: "Hi there, please write this text to the file")
  #
  #   # Set the job priority at queue time
  #   MyJob.enqueue(test_text: "Hi there, please write this important text to the file", priority: :high)
  #
  #   # Place in a different queue to the one defined in the class
  #   MyJob.enqueue(test_text: "Hi there, please write this different text to the file", queue_name: 'other_queue')
  #
  module Job
    # Raise this when your job has failed, but try again as soon as another worker is available.
    class RequeueJob < StandardError; end

    # Raise this when your job has failed, but you don't want to requeue it and try again.
    class RejectJob < StandardError; end

    # Raise thie when you want your job to be executed later (later is defined in {Leveret.configuration.delay_time})
    class DelayJob < StandardError; end

    # Instance methods to mixin with your job
    module InstanceMethods
      # @!attribute params
      #   @return [Paramters] The parameters required for task execution
      attr_accessor :params

      # Create a new job ready for execution
      #
      # @param [Parameters] params Parameters to be consumed by {#perform} when performing the job
      def initialize(params = Parameters.new)
        self.params = params
      end

      # Runs the job and captures any exceptions to turn them into symbols which represent the status of the job
      #
      # @return [Symbol] :success, :requeue, :reject, :delay depending on job success
      def run
        Leveret.log.info "Running #{self.class.name} with #{params}"
        perform
        :success
      rescue Leveret::Job::RequeueJob
        Leveret.log.warn "Requeueing job #{self.class.name} with #{params}"
        :requeue
      rescue Leveret::Job::RejectJob
        Leveret.log.warn "Rejecting job #{self.class.name} with #{params}"
        :reject
      rescue Leveret::Job::DelayJob
        Leveret.log.warn "Delaying job #{self.class.name} with #{params}"
        :delay
      rescue StandardError => e
        Leveret.log.error "#{e.message} when processing #{self.class.name} with #{params}"
        Leveret.configuration.error_handler.call(e, self)
        :reject
      end

      # Run the job with no error handling. Generally you should call {#run} to execute the job since that'll write
      # and log output and call any error handlers if the job goes sideways.
      #
      # @note Your class should override this method to contain the work to be done in this job.
      #
      # @raise [RequeueJob] Reject this job and put it back on the queue for future execution
      # @raise [RejectJob] Reject this job and do not requeue it.
      def perform
        raise NotImplementedError
      end
    end

    # Class methods to mixin with your job
    module ClassMethods
      # Shorthand to intialize a new job and run it with error handling
      #
      # @param [Parameters] params Parameters to pass to the job for execution
      #
      # @return [Symbol] :success, :requeue or :reject depending on job execution
      def perform(params = Parameters.new)
        new(params).run
      end

      # Set a custom queue for this job
      #
      # @param [String] name Name of the queue to assign this job to
      def queue_name(name)
        job_options[:queue_name] = name
      end

      # Set a custom priority for this job
      #
      # @param [Symbol] priority Priority for this job, see {Queue::PRIORITY_MAP} for details
      def priority(priority)
        job_options[:priority] = priority
      end

      # @return [Hash] The current set of options for this job, the +queue_name+ and +priority+.
      def job_options
        @job_options ||= {
          queue_name: Leveret.configuration.default_queue_name,
          priority: :normal
        }
      end

      # Place a job onto the queue for processing by a worker.
      #
      # @param [Hash] params The parameters to be included with the work request. These can be anything, however
      #   the keys +:priority+ and +:queue_name+ are reserved for customising those aspects of the job's execution
      #
      # @option params [Symbol] :priority (job_options[:priority]) Override the class-level priority for this job only
      # @option params [String] :queue_name (job_options[:queue_name]) Override the class-level queue name for this
      #   job only.
      def enqueue(params = {})
        priority = params.delete(:priority) || job_options[:priority]
        q_name = params.delete(:queue_name) || job_options[:queue_name]

        Leveret.log.info "Queuing #{name} to #{q_name} (#{priority}) with #{params}"

        payload = { job: self.name, params: params }
        queue(q_name).publish(payload, priority: priority)
      end

      # @private Cache the queue for this job
      #
      # @param [q_name] The name of the queue we want to cache. If nil it'll use the name defined in
      #   +job_options[:queue_name]+
      # @return [Queue] Cached Queue object for publishing jobs
      def queue(q_name = nil)
        q_name ||= job_options[:queue_name]
        @queue ||= {}
        @queue[q_name] ||= Leveret::Queue.new(q_name)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods
    end
  end
end
