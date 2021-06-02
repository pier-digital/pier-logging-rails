require "test_helper"

class PierLogging::LoggerConfigurationTest < Minitest::Test
  subject { PierLogging::LoggerConfiguration.new }

  context "#sensitive_keywords" do
    should 'transform strings to regexps when adding them' do
      keyword = "blah"
      subject.sensitive_keywords = [keyword]
      assert_equal Regexp.new(keyword), subject.sensitive_keywords.first
    end

    should 'transform symbols to regexps when adding them' do
      keyword = :blah
      subject.sensitive_keywords = [keyword]
      assert_equal Regexp.new(keyword.to_s), subject.sensitive_keywords.first
    end

    should 'be able to add regexps' do
      keyword = /blah/
      subject.sensitive_keywords = [keyword]
      assert_equal keyword, subject.sensitive_keywords.first
    end
  end
end
