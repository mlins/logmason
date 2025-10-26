# frozen_string_literal: true

require "json"
require_relative "base"

module Logmason
  module Formatters
    class Json < Base
      def call(severity, timestamp, progname, payload)
        fields = base_fields(severity, timestamp, payload)
        JSON.generate(fields)
      end
    end
  end
end
