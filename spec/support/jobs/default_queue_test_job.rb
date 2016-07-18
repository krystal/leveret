class DefaultQueueTestJob
  include Leveret::Job

  def perform
    puts "I'm a little teapot"
  end
end
