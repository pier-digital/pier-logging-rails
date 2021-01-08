
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
  end
end