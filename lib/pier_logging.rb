require "rails"
require "ougai"
require "pier_logging/version"
require "pier_logging/logger"
require "pier_logging/request_logger"
require "pier_logging/formatter/base"
require "pier_logging/formatter/json"
require "pier_logging/formatter/readable"

module PierLogging
  def self.logger_configuration
    @logger_configuration ||= LoggerConfiguration.new
  end

  def self.configure_logger
    yield(logger_configuration)
  end

  def self.request_logger_configuration
    @request_logger_configuration ||= RequestLoggerConfiguration.new
  end

  def self.configure_request_logger
    yield(request_logger_configuration)
  end

  class LoggerConfiguration
    attr_reader :app_name, :env, :formatter

    def initialize
      @app_name = nil
      @env = nil
      @formatter = Formatter::Json.new
    end

    def app_name=(app_name)
      raise ArgumentError, "Config 'app_name' must be a String" unless app_name.is_a?(String)
      @app_name = app_name
    end
    
    def env=(env)
      raise ArgumentError, "Config 'env' must be a String" unless env.is_a?(String)
      @env = env
    end

    def formatter=(formatter)
      raise ArgumentError, "Config 'formatter' must be a 'Ougai::Formatters::Base'" unless formatter.is_a?(Ougai::Formatters::Base)
      @formatter = formatter
    end
  end

  class RequestLoggerConfiguration
    attr_reader :enabled, :user_info_getter

    def initialize
      @user_info_getter = nil
      @enabled = false
    end

    def user_info_getter(&block)
      raise ArgumentError, "Config 'user_info_getter' must be a 'Proc'" unless block_given?
      @user_info_getter = block
    end
    
    def enabled=(enabled = false)
      @enabled = enabled
    end
  end
end
