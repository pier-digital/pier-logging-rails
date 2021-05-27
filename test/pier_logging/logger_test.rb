require "test_helper"

class PierLogging::LoggerTest < Minitest::Test
  subject { PierLogging::Logger.new($stdout) }

  context "#log" do
    setup do
      @severity = Ougai::Logger::INFO
      @message = "User logged in"
      @ex = StandardError.new("Repimboca da parafuseta")
      @data = {
        user: "brunodamassa",
        password: "Gruyere"
      }
    end

    context "logging message and data" do
      should "log stuff with redacted data" do
        subject.log(@severity, @message, @data)
      end
    end

    context "loggin only data" do
      should "log stuff with redacted data" do
        subject.log(@severity, @data)
      end
    end

    context "logging an exception" do
      should "log correctly" do
        subject.log(@severity, @ex)
      end
    end
  end
end
