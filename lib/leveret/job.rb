module Leveret
  module Job
    attr_accessor :params

    def initialize(params = {})
      self.params = params
    end

    def perform
      raise NotImplementedError
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :options

      def perform(serialized_params)
        params = deserialize_params(serialized_params)
        new(params).perform
      end

      def job_options(opts = {})
        @options = {
          queue_name: Leveret.configuration.default_routing_key,
          priority: :normal
        }.merge(opts)
      end

      def enqueue(params = {})
        payload = { job: self.name, params: params }
        queue.publish(serialize_params(payload), priority: options[:priority])
      end

      def queue
        @queue ||= Leveret::Queue.new(options[:queue_name])
      end

      def serialize_params(params)
        JSON.dump(params)
      end

      def deserialize_params(json)
        JSON.parse(json)
      end
    end
  end
end
