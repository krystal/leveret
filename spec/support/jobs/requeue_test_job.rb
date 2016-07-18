class RequeueTestJob
  include Leveret::Job

  def perform
    raise RequeueJob, "Do this job later"
  end
end
