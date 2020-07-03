
module PierLogging
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include ActiveSupport::LoggerSilence

    def create_formatter
      PierLogging.logger_configuration.formatter
    end
  end
end