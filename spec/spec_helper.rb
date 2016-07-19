$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'leveret'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |c|
  c.include QueueHelpers

  c.before(:all) do
    flush_queue('test')
    flush_queue('other_test')
  end

  c.after(:each) do
    flush_queue('test')
    flush_queue('other_test')
  end
end
