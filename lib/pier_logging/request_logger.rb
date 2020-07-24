# Requiring only the part that we need
require 'facets/hash/traverse'
module PierLogging
  class RequestLogger
    REDACT_REPLACE_KEYS = [
      /passw(or)?d/i,
      /^pw$/,
      /^pass$/i,
      /secret/i,
      /token/i,
      /api[-._]?key/i,
      /session[-._]?id/i,
      /^connect\.sid$/
    ].freeze
    REDACT_REPLACE_BY = '*'.freeze
    
    attr_reader :logger

    def initialize(app, logger = PierLogging::Logger.new(STDOUT))
      @app = app
      @logger = logger
    end

    def call(env)
      starts_at = Time.now.utc
      begin
        status, type, body = response = @app.call(env)
        log([env, status, type, body, starts_at, Time.now.utc, nil])
      rescue Exception => exception
        status = determine_status_code_from_exception(exception)
        type = determine_type_from_exception(exception)
        body = determine_body_from_exception(exception)
        log([env, status, type, body, starts_at, Time.now.utc, exception])
        raise exception
      end

      response
    end

    # Optimization https://github.com/JuanitoFatas/fast-ruby#function-with-single-array-argument-vs-splat-arguments-code
    def log(args)
      return unless PierLogging.request_logger_configuration.enabled

      env, status, type, body, starts_at, ends_at, _ = args
      request = Rack::Request.new(env)
      request_headers = get_request_headers_from_env(env)
      logger.info redact_hash({
        message: build_message_from_request(request),
        type: 'http',
        duration: ((ends_at - starts_at)*1000).to_i,
        context: {
          user: get_user_info_from_headers(request_headers),
          request_id: env['action_dispatch.request_id'],
          correlation_id: get_correlation_id(env, headers)
        },
        request: {
          headers: request_headers,
          href: request.url,
          body: parse_body(request.POST)
        },
        response: {
          status: status,
          body: response_body(request.path, body),
          type: type['Content-Type'],
        }
      })
    rescue StandardError => error
      # We should never fall in this part as the only errors that could result in this are errors
      # in our logger (inside this same method)
      @logger.error(error.message)
    end 

    private
    def get_request_headers_from_env(env)
      hide_request_headers = PierLogging.request_logger_configuration.hide_request_headers
      
      headers = env.select { |k,v| k[0..4] == 'HTTP_'}.
        transform_keys { |k| k[5..-1].split('_').join('-').upcase }
      
      return redact_hash(headers, hide_request_headers, nil) if hide_request_headers.present?

      headers
    end

    def response_body(request_path, body)
      return nil unless PierLogging.request_logger_configuration.log_response
      
      hide_response_body_for_paths = PierLogging.request_logger_configuration.hide_response_body_for_paths
      return nil if hide_response_body_for_paths && hide_response_body_for_paths.any?{ |path|request_path =~ path }
      
      parse_body(body)
    end

    def build_message_from_request(request)
      [
        request.request_method.upcase, 
        [request.base_url,request.path].join(''),
      ].join(' ')
    end

    def get_user_info_from_headers(headers)
      PierLogging.request_logger_configuration.user_info_getter.call(headers)
    end

    def get_correlation_id(env, headers)
      PierLogging.request_logger_configuration.correlation_id_getter(env, headers) || headers['X-CORRELATION-ID']
    end

    def parse_body(body)
      body_object = get_body_object(body)
      Oj.load(body_object, allow_blank: true)
    rescue
      body_object || body
    end

    def get_body_object(body)
      return body.last if body.is_a? Array # Grape body
      return body.body if body.is_a? ActionDispatch::Response::RackBody # Rails body
      body
    end

    def redact_hash(hash, replace_keys = REDACT_REPLACE_KEYS, replace_by = REDACT_REPLACE_BY)
      hash.traverse do |k,v| 
        should_redact = replace_keys.any?{ |regex| k =~regex }
        if (should_redact)
          [k, replace_by]
        else
          [k, v]
        end
      end
    end

    def determine_body_from_exception(exception)
      { message: exception.message }
    end

    def determine_type_from_exception(exception)
      'application/json'
    end

    def determine_status_code_from_exception(exception)
      exception_wrapper = ActionDispatch::ExceptionWrapper.new(nil, exception)
      exception_wrapper.status_code
    rescue
      500
    end
  end
end
