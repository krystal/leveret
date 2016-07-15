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
      if child = fork
        Leveret.logger.info "Forked to #{child}"
        Process.wait
      else
        job_klass = Object.const_get(msg['job'])
        job_klass.perform(msg['params'])

        exit
      end
    end
  end
end
