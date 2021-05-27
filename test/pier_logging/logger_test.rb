require "test_helper"

class PierLogging::LoggerTest < Minitest::Test
  subject { PierLogging::Logger.new($stdout) }

  context "#log" do
    setup do
      @severity = Ougai::Logger::INFO
      @message = "User logged in"
      @ex = StandardError.new("Repimboca da parafuseta")
      @data = {
        username: "brunodamassa",
        password: "Gruyere"
      }
    end

    context "logging message and data" do
      should "log stuff with redacted data" do
        log = capture_log { subject.log(@severity, @message, @data) }

        assert_equal "*", log["fields"]["password"]
        assert_equal "brunodamassa", log["fields"]["username"]
      end
    end

    context "loggin only data" do
      should "log stuff with redacted data" do
        log = capture_log { subject.log(@severity, @data) }

        assert_equal "*", log["fields"]["password"]
        assert_equal "brunodamassa", log["fields"]["username"]
      end
    end

    context "logging an exception" do
      should "log correctly" do
        log = capture_log { subject.log(@severity, @ex) }

        assert_equal "Repimboca da parafuseta", log["message"]
        assert_equal "StandardError", log["fields"]["err"]["name"]
        assert_equal "Repimboca da parafuseta", log["fields"]["err"]["message"]
      end
    end
  end

  private

  def capture_log(&block)
    out, _ = capture_io do
      yield
    end
    JSON.parse(out)
  end
end
