module Leveret
  # Subscribes to one or more queues and forks workers to perform jobs as they arrive
  #
  # Call {#do_work} to subscribe to all queues and block the main thread.
  class Worker
    extend Forwardable

    # @!attribute queues
    #   @return [Array<Queue>] All of the queues this worker is going to subscribe to
    # @!attribute consumers
    #   @return [Array<Bunny::Consumer>] All of the actively subscribed queues
    attr_accessor :queues, :consumers

    def_delegators :Leveret, :log, :configuration

    # Create a new worker to process jobs from the list of queue names passed
    #
    # @param [Array<String>] queue_names ([Leveret.configuration.default_queue_name]) A list of queue names for this
    #   worker to subscribe to and process
    def initialize(*queue_names)
      queue_names << configuration.default_queue_name if queue_names.empty?

      self.queues = queue_names.map { |name| Leveret::Queue.new(name) }
      self.consumers = []
      @time_to_die = false
    end

    # Subscribe to all of the {#queues} and begin processing jobs from them. This will block the main
    # thread until an interrupt is received.
    def do_work
      log.info "Starting master process for #{queues.map(&:name).join(', ')}"
      prepare_for_work

      loop do
        if @time_to_die
          cancel_subscriptions
          break
        end
        sleep 1
      end
      log.info "Exiting master process"
    end

    private

    # Steps that need to be prepared before we can begin processing jobs
    def prepare_for_work
      setup_traps
      self.process_name = 'leveret-worker-parent'
      start_subscriptions
    end

    # Catch INT and TERM signals and set an instance variable to signal the main loop to quit when possible
    def setup_traps
      trap('INT') do
        @time_to_die = true
      end
      trap('TERM') do
        @time_to_die = true
      end
    end

    # Set the title of this process so it's easier on the eye in top
    def process_name=(name)
      Process.setproctitle(name)
    end

    # Subscribe to each queue defined in {#queues} and add the returned consumer to {#consumers}. This will
    # allow us to gracefully cancel these subscriptions when we need to quit.
    def start_subscriptions
      queues.map do |queue|
        consumers << queue.subscribe do |incoming_message|
          fork_and_run(incoming_message)
        end
      end
    end

    # Send cancel to each consumer in the {#consumers} list. This will end the current subscription.
    def cancel_subscriptions
      log.info "Interrupt received, preparing to exit"
      consumers.each do |consumer|
        log.debug "Cancelling consumer on #{consumer.queue.name}"
        consumer.cancel
      end
    end

    # Fork the current process and run the job described by #payload in the newly created child process.
    # Detach the main process from the child so we can return to the main loop without waiting for it to finish
    # processing the job.
    #
    # @param [Message] payload Message meta and payload to process
    def fork_and_run(incoming_message)
      pid = fork do
        self.process_name = 'leveret-worker-child'
        log.info "[#{incoming_message.delivery_tag}] Forked to child process #{pid} to run" \
          "#{incoming_message.params[:job]}"

        Leveret.reset_connection!
        Leveret.configuration.after_fork.call

        result = perform_job(incoming_message.params)
        result_handler = Leveret::ResultHandler.new(incoming_message)
        result_handler.handle(result)

        log.info "[#{incoming_message.delivery_tag}] Exiting child process #{pid}"
        exit!(0)
      end

      # Master doesn't need to know how it all went down, the worker will report it's own status back to the queue
      Process.detach(pid)
    end

    # Constantize the class name in the payload and execute the job with parameters
    #
    # @param [Parameters] payload The job name and parameters the job requires
    # @return [Symbol] :success, :reject or :requeue depending on how job execution went
    def perform_job(payload)
      job_klass = Object.const_get(payload[:job])
      job_klass.perform(Leveret::Parameters.new(payload[:params]))
    end
  end
end
