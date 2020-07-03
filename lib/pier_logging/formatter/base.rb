
# The base formatter
module PierLogging
  module Formatter
    class Base < Ougai::Formatters::Base
      include Ougai::Formatters::ForJson
      
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Ougai::Formatters::Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)
      end

      def get_message(data)
        # Use `message` (besides `msg` - ougai default) as the message field
        if data.is_a?(Hash)
          msg = data.delete(:msg)
          data[:message] = msg if !data[:message]
        end
        data.delete(:message)
      end

      def get_message_type(data)
        data.delete(:type) || 'default'
      end

      def get_log_content(severity, time, message, message_type, data)
        dump({
          env: PierLogging.logger_configuration.env,
          app: PierLogging.logger_configuration.app_name,
          level: severity.downcase,
          timestamp: time,
          message: message,
          type: message_type,
        }.merge({ fields: data }))
      end

      def _call(severity, time, progname, data)
        message = get_message(data)
        message_type = get_message_type(data)
        get_log_content(severity, time, message, message_type, data)
      end

      def convert_time(data)
        data[:timestamp] = data[:timestamp].utc.iso8601(3)
      end
    end
  end
end