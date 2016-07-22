module Leveret
  # Prettier logging than the default
  class LogFormatter < Logger::Formatter
    SEVERITY_TO_COLOR_MAP = { 'DEBUG' => '0;37', 'INFO' => '32', 'WARN' => '33', 'ERROR' => '31', 'FATAL' => '31',
                              'UNKNOWN' => '37' }.freeze

    def call(severity, datetime, _progname, msg)
      formatted_time = datetime.strftime("%Y-%m-%d %H:%M:%S") << datetime.usec.to_s[0..2].rjust(3)
      color = SEVERITY_TO_COLOR_MAP[severity]

      "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{severity}\033[0m] #{msg2str(msg)} (pid:#{Process.pid})\n"
    end
  end
end
