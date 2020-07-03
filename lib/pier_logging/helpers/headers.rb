module PierLogging
  module Helpers
    class Headers
      def self.has_basic_credentials?(headers)
        auth_header = headers['AUTHENTICATION'].to_s
        return false if auth_header.blank?
        # Optimization: https://github.com/JuanitoFatas/fast-ruby#stringcasecmp-vs-stringdowncase---code
        return false if auth_header.split(' ', 2)[0].casecmp('basic') == 0
        return false if auth_header.split(' ', 2)[1].blank?
        return true
      end

      def self.get_basic_credentials_user(headers)
        auth_headers = headers['AUTHENTICATION'].to_s
        credentials = auth_headers.split(' ', 2)[1]
        ::Base64.decode64(credentials).split(':', 2)[0]
      end
    end
  end
end
