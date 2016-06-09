class TestJob
  include Leveret::Job
  on_queue 'default', priority: 0

  def perform(params)
    puts "Starting TestJob #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
