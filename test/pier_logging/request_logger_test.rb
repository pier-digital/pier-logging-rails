require "test_helper"

class PierLogging::RequestLoggerTest < Minitest::Test


  context "#log" do
    setup do
      PierLogging.request_logger_configuration.sensitive_keywords = [:blah]
      PierLogging.request_logger_configuration.enabled = true
      @logger = PierLogging::Logger.new(STDOUT)
    end

    subject { PierLogging::RequestLogger.new mock(), @logger }

    should 'redact blah' do
      args = [:test, 'foo', 'foo', {blah: 'foo'}, Time.now, Time.now]
      subject.log args
    end
  end
end
