class TestJob
  include Leveret::Job

  queue_name 'test'
  priority :normal

  def perform(params)
    puts "Starting TestJob #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
