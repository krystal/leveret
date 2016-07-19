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
        consumers << queue.subscribe do |msg|
          fork_and_run(msg)
        end
      end
    end

    def fork_and_run(msg)
      read, write = IO.pipe

      pid = fork do
        read.close

        Leveret.configuration.after_fork.call

        job_klass = Object.const_get(msg['job'])
        result = job_klass.perform(msg['params'])

        Marshal.dump(result, write)

        exit!(0)
      end

      write.close
      result = read.read
      Process.wait(pid)

      Marshal.load(result) unless result.blank?
    end
  end
end
