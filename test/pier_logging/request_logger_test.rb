require "test_helper"

class PierLogging::RequestLoggerTest < Minitest::Test
  subject { PierLogging::RequestLogger.new(mock, @logger) }

  context "#log" do
    setup do
      PierLogging.request_logger_configuration.sensitive_keywords = [:blah]
      PierLogging.request_logger_configuration.enabled = true
      @logger = PierLogging::Logger.new($stdout)
      env_mock = Rack::MockRequest.env_for
      body = {blah: "foo", bluh: "plaft"}
      @args = [env_mock, "status", {"Content-type": "12"}, body, Time.now, Time.now]
    end

    teardown do
      PierLogging.request_logger_configuration.enabled = false
    end

    should "redact sensitve keywords" do
      @logger.expects(:info).with do |logged_args|
        redacted_body = logged_args[:response][:body]
        assert_equal "*", redacted_body[:blah]
        assert_equal "plaft", redacted_body[:bluh]
      end

      subject.log(@args)
    end
  end
end
