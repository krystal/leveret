class RejectTestJob
  include Leveret::Job

  def perform
    raise RejectJob, "Can't do this job"
  end
end
