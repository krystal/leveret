module Leveret
  class CLI
    attr_accessor :options

    def initialize(args)
      self.options = {}

      parse_options(args)
      configure_leveret
      start_worker
    end

    private

    def parse_options(args)
      option_parser.parse!(args)
    end

    def configure_leveret
      Leveret.configure do |config|
        config.concurrent_fork_count = options[:processes] if options[:processes]
        config.log_level = options[:log_level] if options[:log_level]
        config.log_file = options[:log_file] if options[:log_file]
      end
    end

    def start_worker
      Leveret::Worker.new(*options[:queues]).do_work
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: leveret_worker [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on "-q", "--queues [QUEUES]", String, "Comma separated list of queues to subscribe to" do |queues|
          options[:queues] = queues.split(',')
        end

        opts.on "-p", "--processes [PROCESSES]", Integer, "Number of concurrent jobs to process" do |processes|
          options[:processes] = processes
        end

        opts.on '-l', '--log-level [LEVEL]', String, "Level of log output (debug, info, warning, error, fatal)" do |lvl|
          options[:log_level] = convert_log_level(lvl)
        end

        opts.on '-o', '--log-output [FILE]', String, "Location to write log file to" do |logfile|
          options[:log_file] = logfile
        end

        opts.on_tail '-h', '--help', "Show this message" do
          STDOUT.puts opts
          exit
        end

        opts.on_tail '-v', '--version', "Show the version" do
          STDOUT.puts Leveret::VERSION
          exit
        end
      end
    end

    def convert_log_level(level)
      case level
      when 'debug' then Logger::DEBUG
      when 'info' then Logger::INFO
      when 'warn' then Logger::WARN
      when 'error' then Logger::ERROR
      when 'fatal' then Logger::FATAL
      else
        Logger::INFO
      end
    end
  end
end
