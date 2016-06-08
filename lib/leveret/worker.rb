module Leveret
  class Worker
    def do_work
      Leveret.mq_channel.prefetch(1)
      queue = Leveret.mq_channel.queue('default_queue', persistent: true, auto_delete: false)
      queue.bind(Leveret.mq_exchange, routing_key: 'default')
      queue.subscribe(block: true) do |_, _, msg|
        msg = JSON.parse(msg)
        Object.const_get(msg['job']).new.perform(msg['params'])
      end
    end
  end
end
