require 'bunny'
require 'json'
require 'logger'

require 'leveret/configuration'
require 'leveret/job'
require 'leveret/log_formatter'
require 'leveret/parameters'
require 'leveret/queue'
require 'leveret/worker'
require "leveret/version"

module Leveret # :nodoc:
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def exchange
      @exchange ||= channel.exchange(Leveret.configuration.exchange_name, type: :direct, durable: true,
        auto_delete: false)
    end

    def channel
      @channel ||= begin
        chan = mq_connection.create_channel
        chan.prefetch(configuration.concurrent_fork_count)
        chan
      end
    end

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
        conn = Bunny.new(amqp: configuration.amqp)
        conn.start
        conn
      end
    end
  end
end
