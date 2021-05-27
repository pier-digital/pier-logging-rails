module PierLogging
  class RequestLogger
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
      logger.info PierLogging::Helpers::Redactor.redact({
        message: build_message_from_request(request),
        type: 'http',
        duration: ((ends_at - starts_at)*1000).to_i,
        context: {
          user: get_user_info_from_headers(request_headers),
          request_id: env['action_dispatch.request_id'],
          correlation_id: get_correlation_id(env, request_headers)
        },
        request: {
          headers: request_headers,
          href: request.url,
          query_string: request.query_string,
          body: request_body(request.path, request.body)
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

      return PierLogging::Helpers::Redactor.redact(headers, hide_request_headers, nil) if hide_request_headers.present?

      headers
    end

    def request_body(request_path, body)
      return nil unless PierLogging.request_logger_configuration.log_request_body

      hide_request_body_for_paths = PierLogging.request_logger_configuration.hide_request_body_for_paths
      return nil if hide_request_body_for_paths&.any?{ |path|request_path =~ path }

      parse_body(body)
    end

    def response_body(request_path, body)
      return nil unless PierLogging.request_logger_configuration.log_response

      hide_response_body_for_paths = PierLogging.request_logger_configuration.hide_response_body_for_paths
      return nil if hide_response_body_for_paths&.any?{ |path|request_path =~ path }

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
      PierLogging.request_logger_configuration.correlation_id_getter.call(env, headers) || headers['X-CORRELATION-ID']
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
