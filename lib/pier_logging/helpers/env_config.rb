module PierLogging
  module Helpers
    class EnvConfig
      def self.for(logger = nil, log_dir: 'log', log_file: PierLogging.logger_configuration.env)
        {
          enabled: log_enabled(logger),
          output: log_output(logger, log_dir, log_file),
          level: log_level(logger),
        }
      end

      private

      def self.log_output(logger, log_dir, log_file)
        return nil unless log_enabled(logger)
        log_output_env = ENV.fetch(output_env_var(logger), 'STDOUT').upcase
        log_output_env == 'STDOUT' ? STDOUT : output_file_name(log_dir, log_file)
      end

      def self.log_enabled(logger)
        ENV.fetch(enabled_env_var(logger), 'true') == 'true'
      end

      def self.log_level(logger)
        ENV.fetch(level_env_var(logger), 'info').upcase
      end

      def self.output_env_var(logger)
        ['LOG', logger ,'OUTPUT'].compact.join('_').upcase
      end

      def self.enabled_env_var(logger)
        ['LOG', logger ,'ENABLED'].compact.join('_').upcase
      end

      def self.level_env_var(logger)
        ['LOG', logger ,'LEVEL'].compact.join('_').upcase
      end

      def self.output_file_name(log_dir, log_file)
        [
          [ log_dir, log_file ].join('/'),
          'log'
        ].join('.')
      end
    end
  end
end
