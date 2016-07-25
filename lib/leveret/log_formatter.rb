module Leveret
  # Prettier logging than the default
  class LogFormatter < Logger::Formatter
    # ANSI colour codes for different message types
    SEVERITY_TO_COLOR_MAP = { 'DEBUG' => '0;37', 'INFO' => '32', 'WARN' => '33', 'ERROR' => '31', 'FATAL' => '31',
                              'UNKNOWN' => '37' }.freeze

    # Build a pretty formatted log line
    #
    # @param [String] severity Log level, one of debug, info, warn, error, fatal  or unknown
    # @param [Time] datetime Timestamp of log event
    # @param [String] _progname (Unused) the name of the progname set in the logger
    # @param [String] msg Body of the log message
    #
    # @return [String] Formatted and coloured log message in the format:
    #   "YYYY-MM-DD HH:MM:SS:USEC [SEVERITY] MESSAGE (pid:Process ID)"
    def call(severity, datetime, _progname, msg)
      formatted_time = datetime.strftime("%Y-%m-%d %H:%M:%S") << datetime.usec.to_s[0..2].rjust(3)
      color = SEVERITY_TO_COLOR_MAP[severity]

      "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{severity}\033[0m] #{msg2str(msg)} (pid:#{Process.pid})\n"
    end
  end
end
