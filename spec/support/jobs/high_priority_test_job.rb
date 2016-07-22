class LowPriorityTestJob
  include Leveret::Job

  queue_name 'test'
  priority :low

  def perform
    Leveret.log.info "Starting High Priority Test Job #{params.inspect}"
    Leveret.log.info "Done"
  end
end
