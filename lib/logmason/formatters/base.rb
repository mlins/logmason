# frozen_string_literal: true

module Logmason
  module Formatters
    class Base
      SENSITIVE_KEYS = %i[password password_confirmation token secret api_key ssn].freeze
      SENSITIVE_HEADERS = %w[authorization cookie set-cookie].freeze

      def call(severity, timestamp, progname, payload)
        raise NotImplementedError, "Subclasses must implement #call"
      end

      protected

      def base_fields(severity, timestamp, payload)
        {
          time: format_timestamp(timestamp),
          level: severity_label(severity)
        }.merge(filter_sensitive(payload))
      end

      def format_timestamp(time)
        time.utc.iso8601(6) # ISO8601 with microseconds
      end

      def severity_label(severity)
        case severity
        when ::Logger::DEBUG then "DEBUG"
        when ::Logger::INFO then "INFO"
        when ::Logger::WARN then "WARN"
        when ::Logger::ERROR then "ERROR"
        when ::Logger::FATAL then "FATAL"
        else "UNKNOWN"
        end
      end

      def filter_sensitive(hash)
        filter_keys = SENSITIVE_KEYS + custom_filter_keys

        hash.transform_keys(&:to_sym).each_with_object({}) do |(key, value), result|
          result[key] = if filter_keys.include?(key)
            "[FILTERED]"
          elsif key == :headers && value.is_a?(Hash)
            filter_headers(value)
          elsif value.is_a?(Hash)
            filter_sensitive(value)
          else
            value
          end
        end
      end

      def filter_headers(headers)
        headers.each_with_object({}) do |(key, value), result|
          result[key] = if SENSITIVE_HEADERS.include?(key.to_s.downcase)
            "[FILTERED]"
          else
            value
          end
        end
      end

      def custom_filter_keys
        Rails.application.config.logmason.filter_keys || []
      end

      def flatten_hash(hash, prefix = nil)
        hash.each_with_object({}) do |(key, value), result|
          new_key = prefix ? "#{prefix}.#{key}" : key.to_s

          if value.is_a?(Hash)
            result.merge!(flatten_hash(value, new_key))
          else
            result[new_key] = value
          end
        end
      end
    end
  end
end
