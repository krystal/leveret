class TestJob
  include Leveret::Job
  job_options queue_name: 'standard', priority: :normal

  def perform(params)
    puts "Starting TestJob #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
