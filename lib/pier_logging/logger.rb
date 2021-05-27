
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

    def _log(severity, *args)
      redacted_args = redact_data(args)
      super(severity, *redacted_args)
    end

    private

    def redact_data(data)
      PierLogging::Helpers::Redactor.redact(data)
    end
  end
end
