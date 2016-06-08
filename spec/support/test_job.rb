class TestJob
  include Leveret::Job
  on_queue 'default'

  def perform(params)
    puts params.inspect
    sleep 10
    puts "AWESOME!"
  end
end
