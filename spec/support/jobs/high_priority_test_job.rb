class LowPriorityTestJob
  include Leveret::Job

  queue_name 'test'
  priority :low

  def perform(params)
    puts "Starting High Priority Test Job #{params.inspect}"
    sleep 5
    puts "Done"
  end
end
