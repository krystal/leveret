require 'spec_helper'

describe Leveret do
  it 'has a version number' do
    expect(Leveret::VERSION).not_to be nil
  end

  it 'has a default configuration' do
    expect(Leveret.configuration).to be_a(Leveret::Configuration)
  end

  it 'can be configured via block' do
    amqp = "ampq://test-address/"

    Leveret.configure do |config|
      config.amqp = amqp
    end

    expect(Leveret.configuration.amqp).to eq(amqp)
  end
end
