require 'spec_helper'

describe Leveret do
  it 'has a version number' do
    expect(Leveret::VERSION).not_to be nil
  end

  describe '.configuration' do
    it { expect(Leveret.configuration).to be_a(Leveret::Configuration) }
  end

  describe '.configure' do
    it 'can be configured using a block' do
      amqp = "ampq://test-address/"

      Leveret.configure do |config|
        config.amqp = amqp
      end

      expect(Leveret.configuration.amqp).to eq(amqp)
    end
  end

  describe '.channel' do
    let(:channel) { Leveret.channel }

    it "must be a bunny channel" do
      expect(channel).to be_a(Bunny::Channel)
    end

    it 'must prefetch only 1 message at a time' do
      expect(channel.prefetch_count).to eq(1)
    end
  end

  describe '.exchange' do
    let(:exchange) { Leveret.exchange }

    it 'must be a bunny exchange' do
      expect(exchange).to be_a(Bunny::Exchange)
    end

    it 'must be named according to the configuration' do
      expect(exchange.name).to eq(Leveret.configuration.exchange_name)
    end

    it 'must survive a rabbitmq restart' do
      expect(exchange.durable?).to be true
    end

    it 'must survive all consumers disconnecting' do
      expect(exchange.auto_delete?).to be false
    end
  end

  describe '.logger' do
    let(:logger) { Leveret.logger }

    it "is a standard ruby logger" do
      expect(logger).to be_a(Logger)
    end

    it "log level matches the configuration" do
      expect(logger.level).to eq(Leveret.configuration.log_level)
    end
  end
end
