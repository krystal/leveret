# Leveret

Leveret is an easy to use RabbitMQ backed job runner.

It's designed specifically to execute long running jobs (multiple hours) while allowing the applicatioin to be
restarted with no adverse effects on the currently running jobs.

Leveret has been tested with Ruby 2.2.3+ and RabbitMQ 3.5.0+.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'leveret'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install leveret

To use Leveret you need a running RabbitMQ installation. If you don't have it installed yet, you can do so via
[Homebrew](https://www.rabbitmq.com/install-homebrew.html) (MacOS), [APT](https://www.rabbitmq.com/install-debian.html)
(Debian/Ubuntu) or [RPM](https://www.rabbitmq.com/install-rpm.html) (Redhat/Fedora).

RabbitMQ version **3.5.0** or higher is recommended as this is the first version to support message priorities.

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

MyOtherQueueJob.enqueue(test_text: "Hi there! Please write me to the test file.")
```

If you don't always want to place the job on your other queue, you can specify the queue name when enqueuing it. Pass
the `queue_name` option when enqueuing the job.

```ruby
MyJob.enqueue(test_text: "Hi there! Please write me to the test file.", queue_name: 'other')
```

### Priorities

Leveret supports 3 levels of job priority, `:low`, `:normal` and `:high`. To set the priority you can define it in your
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
```

To specify priority at enqueue time:

```ruby
MyJob.enqueue(test_text: "Hi there! Please write me to the test file.", priority: :high)
```

### Workers

To start a leveret worker, simply run the `leveret_worker` executable included in the gem. Started with no arguments it
will create a worker monitoring the default queue and process one job at a time.

Changing the queues that a worker monitors requires passing a comma separated list of queue names in the option
`--queues`. The example below watches for jobs on the queues `standard` and `other`.

```bash
bundle exec leveret_worker --queues standard,other
```

By default, workers will only process one job at a time. For each job that is executed, a child process is forked, and
the job run in the new process. When the job completes, the fork exits. We can process more jobs simultaniously simply
by allowing more forks to run. To increase this limit set the `--processes` option. There is no limit to
this variable in Leveret, but you should be aware of your own OS and resource limits.

```bash
bundle exec leveret_worker --processes 5
```

It's also possible to set the log level and output from the command line, call up `--help` for more details.

## Configuration

Configuration in Leveret is done via a configure block. In a Rails application it is recommended you place your
configuration in `config/initializers/leveret.rb`. Leveret comes configured with sane defaults for development, but you
may wish to change some for production use.

```ruby
Leveret.configure do |config|
  # Location of your RabbitMQ server
  config.amqp = "amqp://guest:guest@localhost:5672/"
  # Name of the exchange Levert will create on RabbitMQ
  config.exchange_name = 'leveret_exch'
  # Path to send log output to
  config.log_file = STDOUT
  # Verbosity of log output
  config.log_level = Logger::DEBUG
  # String that is prepended to all queues created in RabbitMQ
  config.queue_name_prefix = 'leveret_queue'
  # Name of the queue to use if none other is specified
  config.default_queue_name = 'standard'
  # A block that should be called every time a child fork is created to process a job
  config.after_fork = proc {}
  # A block that is called whenever an exception occurs in a job
  config.error_handler = proc { |ex| ex }
  # The default number of jobs to process simultaniously, this can be overridden by the PROCESSES
  # environment variable when starting a worker
  config.concurrent_fork_count = 1
end
```

Most of these are pretty self-explanatory and can be left to their default values, however `after_fork` and
`error_handler` could use a little more explaining.

`after_fork` Is called immediately after a child process is forked to run a job. Any connections that need to be
reinitialized on fork should be done so here. For example, if you're using Rails you'll probably want to reconnect
to ActiveRecord here:

```ruby
Leveret.configure do |config|
  config.after_fork = proc do
    ActiveRecord::Base.establish_connection
  end
end
```

`error_handler` is called whenever an exception is raised in your job. These exceptions are caught and logged, but not
raised afterwards. `error_handler` is your chance to decide what to do with these exceptions. You may wish to log them
using a service such as [Airbrake](https://airbrake.io/) or [Sentry](https://getsentry.com/welcome/). To configure an
error handler to log to Sentry the following would be necessary:

```ruby
Leveret.configure do |config|
  config.error_handler = proc do |exception, job|
    job_name = job.class.name
    Raven.capture_exception(exception, tags: {component: job_name})
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/darkphnx/leveret.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

