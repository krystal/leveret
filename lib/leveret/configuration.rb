module Leveret
  class Configuration
    attr_accessor :amqp, :exchange_name

    def initialize
      self.amqp = "amqp://guest:guest@localhost:5672/"
      self.exchange_name = 'leveret'
    end
  end
end
