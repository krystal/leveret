class HighPriorityTestJob
  include Leveret::Job
  on_queue 'standard', priority: 2

  def perform(params)
    puts "Starting High Priority Test Job #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
