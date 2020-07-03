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
          correlation_id: env['action_dispatch.request_id'],
        },
        request: {
          headers: request_headers,
          href: request.url,
          body: parse_body(request.POST)
        },
        response: {
          status: status,
          body: parse_body(body),
          type: type['Content-Type'],
        }
      })
    rescue StandardError => error
      # We should never fall in this part as the only errors that could result in this are errors
      # in our logger (inside this sabe method)
      @logger.error(error.message)
    end

    private
    def get_request_headers_from_env(env)
      env.select { |k,v| k.start_with? 'HTTP_'}.
        transform_keys { |k| k.delete_prefix('HTTP_').split('_').join('-').upcase }
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

    def parse_body(body)
      if body.is_a? String # when string
        JSON.parse(body, nil, allow_blank: true)
      elsif body.is_a? Array # Grape body
        JSON.parse(body.last, nil, allow_blank: true)
      elsif body.is_a? ActionDispatch::Response::RackBody # Rails body
        JSON.parse(body.body, nil, allow_blank: true)
      else
        body
      end
    rescue
      body
    end

    def redact_hash(hash)
      hash.traverse{ |k,v| 
        should_redact = REDACT_REPLACE_KEYS.any?{ |regex| k =~regex };
        if (should_redact)
          [k, REDACT_REPLACE_BY]
        else
          [k, v]
        end
      }
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

    def has_basic_credentials?(headers)
      auth_header = headers['AUTHENTICATION'].to_s
      return false if auth_header.blank?
      # Optimization: https://github.com/JuanitoFatas/fast-ruby#stringcasecmp-vs-stringdowncase---code
      return false if auth_header.split(' ', 2)[0].casecmp('basic') == 0
      return false if auth_header.split(' ', 2)[1].blank?
      return true
    end

    def get_basic_credentials_user(headers)
      auth_headers = headers['AUTHENTICATION'].to_s
      credentials = auth_headers.split(' ', 2)[1]
      ::Base64.decode64(credentials).split(':', 2)[0]
    end 
  end
end