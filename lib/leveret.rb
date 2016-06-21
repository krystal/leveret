require 'bunny'
require 'json'
require 'logger'

require 'leveret/configuration'
require 'leveret/job'
require 'leveret/queue'
require 'leveret/worker'
require "leveret/version"

module Leveret
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def mq_connection
      @mq_connection ||= begin
        conn = Bunny.new(amqp: configuration.amqp)
        conn.start
        conn
      end
    end

    def logger
      @logger ||= begin
        log = Logger.new(configuration.log_file)
        log.level = configuration.log_level
        log
      end
    end
  end
end
