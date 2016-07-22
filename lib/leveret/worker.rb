module Leveret
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
      log.info "Worker starting for #{queues.map(&:name).join(', ')}"
      setup_traps
      subscribe_to_queues

      loop do
        if @time_to_die
          log.info "Interrupt received, preparing to exit"
          consumers.each do |consumer|
            log.debug "Cancelling consumer on #{consumer.queue.name}"
            consumer.cancel
          end
          break
        end
        sleep 1
      end
      log.info "Exiting master process"
    end

    private

    def setup_traps
      trap('INT') do
        @time_to_die = true
      end
    end

    def subscribe_to_queues
      queues.map do |queue|
        consumers << queue.subscribe do |delivery_tag, payload|
          fork_and_run(delivery_tag, payload)
        end
      end
    end

    def fork_and_run(delivery_tag, payload)
      pid = fork do
        Leveret.configuration.after_fork.call

        log.info "[#{delivery_tag}] Forked to child process #{Process.pid} to run #{payload[:job]}"

        job_klass = Object.const_get(payload[:job])
        result = job_klass.perform(Leveret::Parameters.new(payload[:params]))

        log.info "[#{delivery_tag}] Job returned #{result}"

        ack_message(delivery_tag, result)

        log.info "[#{delivery_tag}] Exiting child process #{Process.pid}"
        exit!(0)
      end

      Process.wait(pid)
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
