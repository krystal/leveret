module Leveret
  # Roll up all of the separate parts of an incoming message into a nice convenient object to move around
  #
  # @!attribute delivery_info
  #   @return [Bunny::DeliveryInfo] Full of useful things like the delivery_tag and routing key
  # @!attribute properties
  #   @return [Delivery::Properties] Full of useful things like content-type and priority
  # @!attribute params
  #   @return [Parameters] Deserialized params
  class Message
    extend Forwardable

    attr_accessor :delivery_info, :properties, :params

    def_delegators :delivery_info, :delivery_tag, :routing_key
    def_delegators :properties, :priority

    # @param [Bunny::DeliveryInfo] delivery_info Full of useful things like the delivery_tag and routing key
    # @param [Bunny::Properties] properties Full of useful things like content-type and priority
    # @param [Parameters] Deserialized params parsed from the message
    def initialize(delivery_info, properties, params)
      self.delivery_info = delivery_info
      self.properties = properties
      self.params = params
    end
  end
end
