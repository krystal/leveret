module Leveret
  # Contains everything needed to configure leveret for work
  class Configuration
    attr_accessor :amqp, :exchange_name, :queue_name_prefix, :log_file, :log_level, :default_queue_name, :after_fork,
      :error_handler

    def initialize
      assign_defaults
    end

    def assign_defaults
      self.amqp = "amqp://guest:guest@localhost:5672/"
      self.exchange_name = 'leveret_exch'
      self.log_file = STDOUT
      self.log_level = Logger::DEBUG
      self.queue_name_prefix = 'leveret_queue'
      self.default_queue_name = 'standard'
      self.after_fork = proc {}
      self.error_handler = proc {}
    end
  end
end
