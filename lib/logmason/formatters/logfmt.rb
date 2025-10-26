# frozen_string_literal: true

require_relative "base"

module Logmason
  module Formatters
    class Logfmt < Base
      def call(severity, timestamp, progname, payload)
        fields = base_fields(severity, timestamp, payload)
        flat_fields = flatten_hash(fields)

        flat_fields.map { |k, v| format_pair(k, v) }.join(" ")
      end

      private

      def format_pair(key, value)
        formatted_value = format_value(value)

        # Quote if contains spaces or special chars
        if formatted_value.match?(/[\s="]/)
          "#{key}=\"#{escape_quotes(formatted_value)}\""
        else
          "#{key}=#{formatted_value}"
        end
      end

      def format_value(value)
        case value
        when String then value
        when Time, DateTime then value.iso8601(6)
        when true, false then value.to_s
        when nil then "null"
        else value.to_s
        end
      end

      def escape_quotes(string)
        string.gsub('"', '\"')
      end
    end
  end
end
