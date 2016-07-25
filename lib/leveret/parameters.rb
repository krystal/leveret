module Leveret
  # Provides basic indifferent hash access for jobs, allows strings to be used to access symbol keyed values,
  # or symbols to be used to access string keyed values.
  #
  # Overrides the [] method of the hash, all other calls (except {#serialize}) are delegated to the {#params} object
  #
  # Beware of using both strings and symbols with the same value in the same hash e.g. +{:one => 1, 'one' => 1}+
  # only one of these values will ever be returned.
  class Parameters
    extend Forwardable

    # The parameters hash wrapped up by this object
    attr_accessor :params

    def_delegators :params, :==, :inspect, :to_s

    # @param [Hash] params Hash you wish to access indifferently
    def initialize(params)
      self.params = params || {}
    end

    # Access {#params} indifferently. Tries the passed key directly first, then tries it as a symbol, then tries
    # it as a string.
    #
    # @param [Object] key Key of the item we're trying to access in {#params}
    #
    # @return [Object, nil] Value related to key, or nil if object is not found
    def [](key)
      params[key] || (key.respond_to?(:to_sym) && params[key.to_sym]) || (key.respond_to?(:to_s) && params[key.to_s])
    end

    # Delegate any unknown methods to the {#params} hash
    def method_missing(method_name, *arguments, &block)
      params.send(method_name, *arguments, &block)
    end

    # Check the {#params} hash as well as this class for a method's existence
    def respond_to?(method_name, include_private = false)
      params.respond_to?(method_name, include_private) || super
    end

    # Serialize the current value of {#params}. Outputs JSON.
    #
    # @return [String] JSON encoded representation of the params
    def serialize
      JSON.dump(params)
    end

    # Create a new instance of this class from a a serialized JSON object.
    #
    # @return [Parameters] New instance based on the passed JSON
    def self.from_json(json)
      params = JSON.load(json)
      new(params)
    end
  end
end
