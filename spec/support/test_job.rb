class TestJob
  include Leveret::Job
  on_queue 'default'

  def perform(params)
    puts "AWESOME!"
    puts params.inspect
  end
end
