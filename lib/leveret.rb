require 'bunny'
require 'json'

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
  end
end
