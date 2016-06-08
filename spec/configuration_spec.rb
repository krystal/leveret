require 'spec_helper'

describe Leveret::Configuration do
  it 'has a default set of configuration params' do
    config = Leveret::Configuration.new

    expect(config.amqp).to eq("amqp://guest:guest@localhost:5672/")
    expect(config.exchange_name).to eq('leveret')
  end
end
