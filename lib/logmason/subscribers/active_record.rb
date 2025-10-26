# frozen_string_literal: true

module Logmason
  module Subscribers
    class ActiveRecord
      def self.attach
        ActiveSupport::Notifications.subscribe("sql.active_record") do |name, started, finished, unique_id, payload|
          # Skip schema queries and cached queries
          next if payload[:name] == "SCHEMA"
          next if payload[:cached]

          duration_ms = ((finished - started) * 1000).round(2)

          # Increment metrics in request context
          RequestContext.increment_metric(:db_queries, 1)

          current_duration = RequestContext.current_context.dig(:metrics, :db_duration_ms) || 0
          RequestContext.add_metric(:db_duration_ms, current_duration + duration_ms)
        end
      end
    end
  end
end
