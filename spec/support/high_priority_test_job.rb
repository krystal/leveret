class HighPriorityTestJob
  include Leveret::Job
  job_options queue_name: 'test', priority: :high

  def perform(params)
    puts "Starting High Priority Test Job #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
