module Leveret
  # Subscribes to one or more queues and forks workers to perform jobs as they arrive
  #
  # Call #do_work to subscribe to all queues and block the main thread.
  class Worker
    extend Forwardable

    attr_accessor :queues, :consumers

    def_delegators :Leveret, :log, :channel

    def initialize(*queue_names)
      queue_names = [Leveret.configuration.default_queue_name] if queue_names.empty?

      self.queues = queue_names.map { |name| Leveret::Queue.new(name) }
      self.consumers = []
      @time_to_die = false
    end

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

    def prepare_for_work
      setup_traps
      self.process_name = 'leveret-worker-parent'
      start_subscriptions
    end

    def setup_traps
      trap('INT') do
        @time_to_die = true
      end
      trap('TERM') do
        @time_to_die = true
      end
    end

    def process_name=(name)
      Process.setproctitle(name)
    end

    def start_subscriptions
      queues.map do |queue|
        consumers << queue.subscribe do |delivery_tag, payload|
          fork_and_run(delivery_tag, payload)
        end
      end
    end

    def cancel_subscriptions
      log.info "Interrupt received, preparing to exit"
      consumers.each do |consumer|
        log.debug "Cancelling consumer on #{consumer.queue.name}"
        consumer.cancel
      end
    end

    def fork_and_run(delivery_tag, payload)
      pid = fork do
        self.process_name = 'leveret-worker-child'
        log.info "[#{delivery_tag}] Forked to child process #{pid} to run #{payload[:job]}"

        Leveret.configuration.after_fork.call

        result = perform_job(payload)
        log.info "[#{delivery_tag}] Job returned #{result}"
        ack_message(delivery_tag, result)

        log.info "[#{delivery_tag}] Exiting child process #{pid}"
        exit!(0)
      end

      # Master doesn't need to know how it all went down, the worker will report it's own status back to the queue
      Process.detach(pid)
    end

    def perform_job(payload)
      job_klass = Object.const_get(payload[:job])
      job_klass.perform(Leveret::Parameters.new(payload[:params]))
    end

    def ack_message(delivery_tag, result)
      if result == :reject
        log.debug "[#{delivery_tag}] Rejecting message"
        channel.reject(delivery_tag)
      elsif result == :requeue
        log.debug "[#{delivery_tag}] Requeueing message"
        channel.reject(delivery_tag, true)
      else
        log.debug "[#{delivery_tag}] Acknowledging message"
        channel.acknowledge(delivery_tag)
      end
    end
  end
end
