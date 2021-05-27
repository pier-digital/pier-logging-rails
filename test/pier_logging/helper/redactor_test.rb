require 'test_helper'

class PierLogging::Helpers::RedactorTest < Minitest::Test
  subject { PierLogging::Helpers::Redactor }

  context '.redact' do
    setup do
      PierLogging.request_logger_configuration.sensitive_keywords = [:sensitive_key]
    end
    context 'with a hash' do
      setup do
        @hash = {
          sensitive_key: "Amar é fogo que arde sem se ver",
          not_sensitive: 'Vai Rabetão tão tão no chão',
          password: 'Que não seja imortal, posto que é chama'
        }
      end
      should 'redact only sensitive stuff' do
        response = subject.redact(@hash)

        assert_equal '*', response[:password]
        assert_equal '*', response[:sensitive_key]
        assert_equal 'Vai Rabetão tão tão no chão', response[:not_sensitive]
      end
    end
  end
end
