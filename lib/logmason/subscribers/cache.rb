# frozen_string_literal: true

module Logmason
  module Subscribers
    class Cache
      def self.attach
        ActiveSupport::Notifications.subscribe("cache_read.active_support") do |name, started, finished, unique_id, payload|
          if payload[:hit]
            RequestContext.increment_metric(:cache_hits, 1)
          else
            RequestContext.increment_metric(:cache_misses, 1)
          end
        end
      end
    end
  end
end
