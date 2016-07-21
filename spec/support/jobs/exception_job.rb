class ExceptionJob
  class ExceptionJobError < StandardError; end

  include Leveret::Job

  queue_name 'test'

  def perform
    raise ExceptionJobError, "This job went wrong"
  end
end
