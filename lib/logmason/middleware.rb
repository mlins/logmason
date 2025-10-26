# frozen_string_literal: true

module Logmason
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      # Initialize request context
      RequestContext.init_request(
        request_id: request.request_id,
        start_time: Time.now
      )

      # Store request info for logging
      RequestContext.add_metric(:remote_addr, request.remote_ip)
      RequestContext.add_metric(:user_agent, request.user_agent)
      RequestContext.add_metric(:req_content_length, request.content_length || 0)
      RequestContext.add_metric(:req_content_type, request.content_type || "")
      RequestContext.add_metric(:proto, env["SERVER_PROTOCOL"] || "HTTP/1.1")

      # Allow app to add custom context
      if (custom_context = env["structured_logger.context"])
        custom_context.each { |k, v| RequestContext.add_metric(k, v) }
      end

      @app.call(env)
    ensure
      # Always clean up thread-local storage
      RequestContext.clear
    end
  end
end
