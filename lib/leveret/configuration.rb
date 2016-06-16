module Leveret
  class Configuration
    attr_accessor :amqp, :exchange_name, :queue_name

    def initialize
      self.amqp = "amqp://guest:guest@localhost:5672/"
      self.exchange_name = 'leveret_exch'
      self.queue_name = 'leveret_queue'
    end
  end
end
