class HighPriorityTestJob
  include Leveret::Job

  queue_name 'test'
  priority :high

  def perform
    Leveret.log.info "Starting High Priority Test Job #{params.inspect}"
    Leveret.log.info "Done"
  end
end
