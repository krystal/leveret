class TestJob
  include Leveret::Job

  queue_name 'test'
  priority :normal

  def perform
    Leveret.logger.info "Starting TestJob #{params.inspect}"
    Leveret.logger.info "Done"
  end
end
