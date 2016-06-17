class HighPriorityTestJob
  include Leveret::Job
  job_options queue_name: 'standard', priority: :high

  def perform(params)
    puts "Starting High Priority Test Job #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
