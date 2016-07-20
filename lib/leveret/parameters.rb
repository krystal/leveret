module Leveret
  # Provides basic indifferent hash access for jobs
  class Parameters
    attr_accessor :params

    def initialize(params)
      self.params = params || {}
    end

    def ==(other)
      params == other
    end

    def [](key)
      params[key] || (key.respond_to?(:to_sym) && params[key.to_sym]) || (key.respond_to?(:to_s) && params[key.to_s])
    end

    def method_missing(method_name, *arguments, &block)
      params.send(method_name, *arguments, &block)
    end

    def respond_to?(method_name, include_private = false)
      params.respond_to?(method_name, include_private)
    end

    def serialize
      JSON.dump(params)
    end

    def self.from_json(json)
      params = JSON.load(json)
      new(params)
    end
  end
end
