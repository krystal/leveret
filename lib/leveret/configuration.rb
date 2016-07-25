module Leveret
  # Contains everything needed to configure leveret for work. Sensible defaults are included
  # and will be initialized with the class.
  #
  # @!attribute amqp
  #   @return [String] Location of your RabbitMQ server. Default: +"amqp://guest:guest@localhost:5672/"+
  # @!attribute exchange_name
  #   @return [String] Name of the exchange for Leveret to publish messages to. Default: +"leveret_exch"+
  # @!attribute queue_name_prefix
  #   @return [String] This value will be prefixed to all queues created on your RabbitMQ instance.
  #     Default: +"leveret_queue"+
  # @!attribute log_file
  #   @return [String] The path where logfiles should be written to. Default: +STDOUT+
  # @!attribute log_level
  #   @return [Integer] The log severity which should be output to the log. Default: +Logger::DEBUG+
  # @!attribute default_queue_name
  #   @return [String] The name of the queue that will be use unless explicitly specified in a job. Default:
  #     +"standard"+
  # @!attribute after_fork
  #   @return [Proc] A proc which will be executed in a child after forking to process a message. Default: +proc {}+
  # @!attribute error_handler
  #   @return [Proc] A proc which will be called if a job raises an exception. Default: +proc {|ex| ex }+
  # @!attribute concurrent_fork_count
  #   @return [Integer] The number of jobs that can be processes simultanously. Default: +1+
  class Configuration
    attr_accessor :amqp, :exchange_name, :queue_name_prefix, :log_file, :log_level, :default_queue_name, :after_fork,
      :error_handler, :concurrent_fork_count

    # Create a new instance of Configuration with a set of sane defaults.
    def initialize
      assign_defaults
    end

    private

    def assign_defaults
      self.amqp = "amqp://guest:guest@localhost:5672/"
      self.exchange_name = 'leveret_exch'
      self.log_file = STDOUT
      self.log_level = Logger::DEBUG
      self.queue_name_prefix = 'leveret_queue'
      self.default_queue_name = 'standard'
      self.after_fork = proc {}
      self.error_handler = proc { |ex| ex }
      self.concurrent_fork_count = 1
    end
  end
end
