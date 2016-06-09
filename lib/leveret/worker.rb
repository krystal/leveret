module Leveret
  class Worker
    def do_work
      Leveret.mq_channel.prefetch(1)
      queue = Leveret.mq_channel.queue('default_queue', persistent: true, auto_delete: false, arguments: { 'x-max-priority' => 2 })
      queue.bind(Leveret.mq_exchange, routing_key: 'default')
      queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, msg|
        Leveret.mq_channel.acknowledge(delivery_info.delivery_tag, false)
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
