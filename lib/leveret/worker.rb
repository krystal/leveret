module Leveret
  class Worker
    def do_work
      queue = Leveret::Queue.new
      queue.subscribe do |channel, _delivery_info, _properties, msg|
        fork_and_run(msg)
      end
    end

    private

    def fork_and_run(msg)
      if @child = fork
        puts "Forked to #{@child}"
        Process.wait
      else
        msg = JSON.parse(msg)

        job_klass = Object.const_get(msg['job'])
        job_klass.new.perform(msg['params'])

        exit
      end
    end
  end
end
