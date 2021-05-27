
module PierLogging
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include ActiveSupport::LoggerSilence if defined?(ActiveSupport::LoggerSilence)

    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def create_formatter
      PierLogging.logger_configuration.formatter
    end

    def log(severity, message = nil, ex = nil, data = nil, &block)
      redacted_message = redact_data(message)
      redacted_ex = redact_data(ex)
      redacted_data = redact_data(data)
      super(severity, redacted_message, redacted_ex, redacted_data, &block)
    end

    private

    def redact_data(data)
      PierLogging::Helpers::Redactor.redact(data)
    end
  end
end
