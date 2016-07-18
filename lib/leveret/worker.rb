module Leveret
  class Worker
    attr_accessor :queues

    def initialize(*queue_names)
      queue_names = [Leveret.configuration.default_queue_name] if queue_names.empty?
      self.queues = queue_names.map { |name| Leveret::Queue.new(name) }
    end

    def do_work
      subscribe_to_queues
      loop do
        sleep 10
      end
    end

    def subscribe_to_queues
      queues.each do |queue|
        queue.subscribe do |_delivery_info, _properties, msg|
          fork_and_run(msg)
        end
      end
    end

    private

    def fork_and_run(msg)
      read, write = IO.pipe

      pid = fork do
        read.close

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
