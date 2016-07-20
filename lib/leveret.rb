require 'bunny'
require 'json'
require 'logger'

require 'leveret/configuration'
require 'leveret/job'
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
        chan.prefetch(1)
        chan
      end
    end

    def logger
      @logger ||= begin
        log = Logger.new(configuration.log_file)
        log.level = configuration.log_level
        log
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
