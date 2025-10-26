# frozen_string_literal: true

module Logmason
  module Subscribers
    class Exception
      def self.attach
        ActiveSupport::Notifications.subscribe("process_action.action_controller") do |name, started, finished, unique_id, payload|
          next unless (exception = payload[:exception_object])

          ctx = RequestContext.current_context
          backtrace_limit = Rails.application.config.logmason.backtrace_lines || 10

          error_data = {
            msg: "Exception during request",
            error_class: exception.class.name,
            error_message: exception.message,
            backtrace: exception.backtrace&.first(backtrace_limit),
            request_id: ctx[:request_id],
            controller: payload[:controller],
            action: payload[:action],
            path: payload[:path]
          }.compact

          # Log immediately (not waiting for request end)
          Rails.logger.add(::Logger::ERROR, error_data)
        end
      end
    end
  end
end
