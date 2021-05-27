# Requiring only the part that we need
require 'facets/hash/traverse'

module PierLogging
    module Helpers
      class Redactor
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

          class << self
            def redact(obj, replace_keys = nil, replace_by = REDACT_REPLACE_BY)
              replace_keys ||= sensitive_keywords
              if obj.is_a?(Array)
                redact_array(obj, replace_keys, replace_by)
              elsif obj.is_a?(Hash)
                redact_hash(obj, replace_keys, replace_by)
              elsif obj.respond_to?(:to_hash)
                redact_hash(obj.to_hash, replace_keys, replace_by)
              else
                obj
              end
            end

            private

            def sensitive_keywords
                REDACT_REPLACE_KEYS + PierLogging.request_logger_configuration.sensitive_keywords
            end

            def redact_array(arr, replace_keys, replace_by = REDACT_REPLACE_BY)
              raise StandardError, 'Could not redact_array for non-array objects' unless arr.is_a? Array
              arr.map { |el| redact(el, replace_keys, replace_by) }
            end

            def redact_hash(hash, replace_keys, replace_by = REDACT_REPLACE_BY)
                raise StandardError, 'Could not redact_hash for non-hash objects' unless hash.is_a? Hash
                hash.traverse do |k,v|
                    should_redact = replace_keys.any?{ |regex| k =~ regex }
                    if (should_redact)
                        [k, replace_by]
                    else
                        case v
                        when Array then [k, redact_array(v, replace_keys, replace_by)]
                        else
                        [k, v]
                        end
                    end
                end
            end
        end
      end
    end
end
