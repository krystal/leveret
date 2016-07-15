require 'spec_helper'

describe Leveret::Configuration do
  it 'has a default set of configuration params' do
    config = Leveret::Configuration.new

    expect(config.amqp).to eq("amqp://guest:guest@localhost:5672/")
    expect(config.exchange_name).to eq('leveret_exch')
    expect(config.queue_name_prefix).to eq('leveret_queue')
    expect(config.log_file).to eq('/tmp/leveret.log')
    expect(config.log_level).to eq(Logger::DEBUG)
    expect(config.default_queue_name).to eq('standard')
  end
end
