require 'spec_helper'

describe Leveret::Configuration do
  it 'has a default set of configuration params' do
    config = Leveret::Configuration.new

    expect(config.amqp).to eq("amqp://guest:guest@localhost:5672")
    expect(config.exchange_name).to eq('leveret_exch')
    expect(config.queue_name_prefix).to eq('leveret_queue')
    expect(config.delay_exchange_name).to eq('leveret_delay_exch')
    expect(config.delay_queue_name).to eq('leveret_delay_queue')
    expect(config.delay_time).to eq(10_000)
    expect(config.log_file).to eq(STDOUT)
    expect(config.log_level).to eq(Logger::DEBUG)
    expect(config.default_queue_name).to eq('standard')
    expect(config.after_fork).to be_a(Proc)
    expect(config.error_handler).to be_a(Proc)
    expect(config.concurrent_fork_count).to eq(1)
  end
end
