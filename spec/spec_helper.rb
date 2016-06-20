$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'leveret'

Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each {|file| require file }

RSpec.configure do |c|
  c.include QueueHelpers

  c.before(:each) do
    flush_queue
  end
end
