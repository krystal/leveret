require 'bunny'
require 'json'
require 'logger'

require 'leveret/configuration'
require 'leveret/delay_queue'
require 'leveret/job'
require 'leveret/log_formatter'
require 'leveret/message'
require 'leveret/parameters'
require 'leveret/queue'
require 'leveret/result_handler'
require 'leveret/worker'
require "leveret/version"

# Top level module, contains things that are required globally by Leveret, such as configuration,
# the RabbitMQ channel and the logger.
module Leveret
  class << self
    # @!attribute [w] configuration
    #   @return [Configuration] Set a totally new configuration object
    attr_writer :configuration

    # @return [Configuration] The current configuration of Leveret
    def configuration
      @configuration ||= Configuration.new
    end

    # Allows leveret to be configured via a block
    #
    # @see Configuration Attributes that can be configured
    # @yield [config] The current configuration object
    def configure
      yield(configuration) if block_given?
    end

    # Connect to the RabbitMQ exchange that Leveret uses, used by the {Queue} for publishing and subscribing, not
    # recommended for general use.
    #
    # @see http://reference.rubybunny.info/Bunny/Exchange.html Bunny documentation
    # @return [Bunny::Exchange] RabbitMQ exchange
    def exchange
      @exchange ||= channel.exchange(Leveret.configuration.exchange_name, type: :direct, durable: true,
        auto_delete: false)
    end

    # Connect to the RabbitMQ channel that {Queue} and {Worker} both use. This channel is not thread safe, so should
    # be reinitialized if necessary. Not recommended for general use.
    #
    # @see http://reference.rubybunny.info/Bunny/Channel.html Bunny documentation
    # @return [Bunny::Channel] RabbitMQ chanel
    def channel
      @channel ||= begin
        chan = mq_connection.create_channel
        chan.prefetch(configuration.concurrent_fork_count)
        chan
      end
    end

    def delay_queue
      @delay_queue ||= Leveret::DelayQueue.new
    end

    def reset_connection!
      @mq_connection = nil
      @channel = nil
      @delay_queue = nil
    end

    # Logger used throughout Leveret, see {Configuration} for config options.
    #
    # @return [Logger] Standard ruby logger
    def log
      @log ||= Logger.new(configuration.log_file).tap do |log|
        log.level = configuration.log_level
        log.progname = 'Leveret'
        log.formatter = Leveret::LogFormatter.new
      end
    end

    private

    def mq_connection
      @mq_connection ||= begin
        conn = Bunny.new(configuration.amqp)
        conn.start
        conn
      end
    end
  end
end
