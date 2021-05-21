require "rails"
require "ougai"
require "awesome_print"
require "facets/hash/traverse"
require "pier_logging/version"
require "pier_logging/logger"
require "pier_logging/request_logger"
require "pier_logging/formatter/base"
require "pier_logging/formatter/json"
require "pier_logging/formatter/readable"
require "pier_logging/helpers/headers"
require "pier_logging/helpers/env_config"

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
    attr_reader :enabled, :user_info_getter, :hide_request_body_for_paths, :hide_response_body_for_paths, 
                :log_request_body, :log_response, :hide_request_headers, :correlation_id_getter, :sensitive_keywords

    def initialize
      @user_info_getter = ->(_ = nil) { nil }
      @enabled = false
      @hide_request_body_for_paths = nil
      @hide_response_body_for_paths = nil
      @log_request_body = true
      @log_response = true
      @hide_request_headers = nil
      @correlation_id_getter = ->(_ = nil, _ = nil) { nil }
      @sensitive_keywords = []
    end

    def user_info_getter=(proc)
      raise ArgumentError, "Config 'user_info_getter' must be a 'Proc'" unless proc.is_a? Proc
      @user_info_getter = proc
    end

    def log_request_body=(log_request_body)
      raise ArgumentError, "Config 'log_request_body' must be a 'boolean'" unless !!log_request_body == log_request_body
      @log_request_body = log_request_body
    end

    def log_response=(log_response)
      raise ArgumentError, "Config 'log_response' must be a 'boolean'" unless !!log_response == log_response
      @log_response = log_response
    end

    def hide_request_body_for_paths=(hide_request_body_for_paths)
      unless (hide_request_body_for_paths.is_a? Array) && (hide_request_body_for_paths.all?{|item| item.is_a? Regexp})
        raise ArgumentError, "Config 'hide_request_body_for_paths' must be an 'Array of Regexps'" 
      end
      
      @hide_request_body_for_paths = hide_request_body_for_paths
    end

    def hide_response_body_for_paths=(hide_response_body_for_paths)
      unless (hide_response_body_for_paths.is_a? Array) && (hide_response_body_for_paths.all?{|item| item.is_a? Regexp})
        raise ArgumentError, "Config 'hide_response_body_for_paths' must be an 'Array of Regexps'" 
      end
      
      @hide_response_body_for_paths = hide_response_body_for_paths
    end

    def hide_request_headers=(hide_request_headers)
      unless (hide_request_headers.is_a? Array) && (hide_request_headers.all?{|item| item.is_a? Regexp})
        raise ArgumentError, "Config 'hide_request_headers' must be an 'Array of Regexps'" 
      end
      @hide_request_headers = hide_request_headers
    end
    
    def enabled=(enabled = false)
      raise ArgumentError, "Config 'enabled' must be a 'boolean'" unless !!enabled == enabled
      @enabled = enabled
    end

    def correlation_id_getter=(proc)
      raise ArgumentError, "Config 'correlation_id_getter' must be a 'Proc'" unless proc.is_a? Proc
      @correlation_id_getter = proc
    end

    def sensitive_keywords=(keywords)
      @sensitive_keywords += keywords
    end
  end
end
