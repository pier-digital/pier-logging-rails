# A Readable formatter
module PierLogging
  module Formatter
    class Readable < Base
      def get_log_content(severity, time, message, message_type, data)
        super.ai
      end
    end
  end
end
