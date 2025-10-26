# frozen_string_literal: true

module Logmason
  module Subscribers
    class ActionController
      def self.attach
        ActiveSupport::Notifications.subscribe("process_action.action_controller") do |name, started, finished, unique_id, payload|
          ctx = RequestContext.current_context
          duration_ms = ((finished - started) * 1000).round(2)

          # Get user_id from Current.user (available after authentication)
          user_id = begin
            Current.user&.id
          rescue
            nil
          end

          # Build request log with all accumulated data
          log_data = {
            msg: "Request",
            method: payload[:method],
            path: payload[:path],
            format: payload[:format],
            controller: payload[:controller],
            action: payload[:action],
            status: payload[:status],
            duration_ms: duration_ms,
            request_id: ctx[:request_id],
            user_id: user_id,
            allocations: payload[:allocations],
            view_runtime_ms: payload[:view_runtime]&.round(2),
            db_runtime_ms: payload[:db_runtime]&.round(2)
          }

          # Add metrics from context
          if (metrics = ctx[:metrics])
            log_data[:db_queries] = metrics[:db_queries] if metrics[:db_queries]
            log_data[:db_duration_ms] = metrics[:db_duration_ms]&.round(2) if metrics[:db_duration_ms]
            log_data[:cache_hits] = metrics[:cache_hits] if metrics[:cache_hits]
            log_data[:cache_misses] = metrics[:cache_misses] if metrics[:cache_misses]

            # Add request metadata (from middleware)
            log_data[:remote_addr] = metrics[:remote_addr] if metrics[:remote_addr]
            log_data[:user_agent] = metrics[:user_agent] if metrics[:user_agent]
            log_data[:req_content_length] = metrics[:req_content_length] if metrics[:req_content_length]
            log_data[:req_content_type] = metrics[:req_content_type] if metrics[:req_content_type]
            log_data[:proto] = metrics[:proto] if metrics[:proto]
          end

          # Remove nil values
          log_data.compact!

          # Determine log level based on status
          level = case payload[:status]
          when 500..599 then ::Logger::ERROR
          when 400..499 then ::Logger::WARN
          else ::Logger::INFO
          end

          Rails.logger.add(level, log_data)
        end
      end
    end
  end
end
