class HighPriorityTestJob
  include Leveret::Job
  on_queue 'default', priority: 2

  def perform(params)
    puts "Starting High Priority Test Job #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
