$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'leveret'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |c|
  c.include QueueHelpers

  c.before(:all) do
    Leveret.configure do |conf|
      conf.log_level = Logger::ERROR
      conf.queue_name_prefix = 'leveret_test_queue'
      conf.default_queue_name = 'test'
      conf.exchange_name = 'leveret_test_exch'
    end

    flush_queue('test')
    flush_queue('other')
  end

  c.after(:each) do
    flush_queue('test')
    flush_queue('other')
  end
end
