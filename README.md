# Leveret

Leveret is an easy to use RabbitMQ backed job runner.

It's designed specifically to execute long running jobs (multiple hours) while allowing the applicatioin to be
restarted with no adverse effects on the currently running jobs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'leveret'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install leveret

## Usage

To create a job include `Leveret::Job` in a new class, and define a `perform` method that will do the work in
your job. Call `enqueue` on your new class with any parameters you want passed to the job at execution time.

```ruby
class MyJob
  include Leveret::Job

  def perform
    File.open('/tmp/leveret-test-file.txt', 'a+') do |f|
      f.puts params[:test_text]
    end

    sleep 5 # Job takes a long time
  end
end

MyJob.enqueue(test_text: "Hi there! Please write me to the test file.")
```

Now start a worker to execute the job:

```bash
bundle exec leveret_worker
```

### Queues

By default all are defined on a single standard queue (see Configuration for details). However, it's possible to use
multiple queues for different jobs. To do this set the `queue_name` in your job class. You'll also need to tell the
worker about your new queue when starting that.

```ruby
class MyOtherQueueJob
  include Leveret::Job

  queue_name 'other'

  def perform
    # ...
  end
end

MyOtherQueueJob.enqueue
```

If you don't always want to place the job on your other queue, you can specify the queue name when enqueuing it. Pass
the `queue_name` option when enqueuing the job.

```ruby
MyJob.enqueue(test_text: "Hi there! Please write me to the test file.", queue_name: 'other')
```

When starting a worker you can pass multiple queue names as a comma separated list. We'll start a worker that will
process jobs on the standard queue, and the new `other` queue.

```bash
bundle exec leveret_worker QUEUES=standard,other
```

### Priorities

Leveret supports 3 levels of job priority, `low`, `normal` and `high`. To set the priority you can define it in your
job class, or specify it at enqueue time by passing the `priority` option.

```ruby
class MyHighPriorityMyJob
  include Leveret::Job

  priority :high

  def perform
    # very important work...
  end
end

MyHighPriorityJob.enqueue

# or...

MyJob.enqueue(priority: :high)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/leveret.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

