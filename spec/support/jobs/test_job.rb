class TestJob
  include Leveret::Job

  queue_name 'test'
  priority :normal

  def perform
    Leveret.log.info "Starting TestJob #{params.inspect}"
    Leveret.log.info "Done"
  end
end
