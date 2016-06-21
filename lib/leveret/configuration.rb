module Leveret
  class Configuration
    attr_accessor :amqp, :exchange_name, :queue_name, :log_file, :log_level, :default_routing_key

    def initialize
      self.amqp = "amqp://guest:guest@localhost:5672/"
      self.exchange_name = 'leveret_exch'
      self.queue_name = 'leveret_queue'
      self.log_file = File.join('/', 'tmp', 'leveret.log')
      self.log_level = Logger::DEBUG
      self.default_routing_key = 'standard'
    end
  end
end
