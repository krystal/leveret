module Leveret
  class Worker
    attr_accessor :queues, :consumers

    def initialize(*queue_names)
      queue_names = [Leveret.configuration.default_queue_name] if queue_names.empty?

      self.queues = queue_names.map { |name| Leveret::Queue.new(name) }
      self.consumers = []
      @time_to_die = false
    end

    def do_work
      setup_traps
      subscribe_to_queues

      loop do
        if @time_to_die
          consumers.each(&:cancel)
          break
        end
        sleep 3
      end
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

        job_klass = Object.const_get(payload['job'])
        result = job_klass.perform(payload['params'])

        ack_message(delivery_tag, result)

        exit!(0)
      end

      Process.wait(pid)
    end

    def channel
      Leveret.channel
    end

    def ack_message(delivery_tag, result)
      if result == :reject
        channel.reject(delivery_tag)
      elsif result == :requeue
        channel.reject(delivery_tag, true)
      else
        channel.acknowledge(delivery_tag)
      end
    end
  end
end
