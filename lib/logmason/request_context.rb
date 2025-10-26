# frozen_string_literal: true

module Logmason
  class RequestContext
    CONTEXT_KEY = :logmason_context

    class << self
      def init_request(request_id:, start_time: Time.now)
        Thread.current[CONTEXT_KEY] = {
          request_id: request_id,
          start_time: start_time,
          logs: [],
          metrics: {}
        }
      end

      def add_log(payload)
        return unless in_request?
        current_context[:logs] << payload
      end

      def add_metric(key, value)
        return unless in_request?
        current_context[:metrics][key] = value
      end

      def increment_metric(key, amount = 1)
        return unless in_request?
        current_context[:metrics][key] ||= 0
        current_context[:metrics][key] += amount
      end

      def current_context
        Thread.current[CONTEXT_KEY] || {}
      end

      def in_request?
        Thread.current[CONTEXT_KEY].present?
      end

      def clear
        Thread.current[CONTEXT_KEY] = nil
      end
    end
  end
end
