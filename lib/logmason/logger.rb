# frozen_string_literal: true

require "logger"
require "monitor"

module Logmason
  class Logger < ::Logger
    def initialize(formatter: nil, broadcast_logger: nil)
      super($stdout)

      # Formatter is for STDOUT only (JSON or LOGFMT)
      @formatter = formatter || default_formatter
      # Broadcast logger (e.g., AppSignal) receives plaintext + attributes
      @broadcast_logger = broadcast_logger
      @mon = Monitor.new
      self.level = ::Logger::INFO
    end

    # Silence logging within a block (used by Rails for health checks, etc.)
    def silence(severity = ::Logger::ERROR)
      old_level = level
      self.level = severity
      yield
    ensure
      self.level = old_level
    end

    # Override add to support both string and hash messages
    def add(severity, message = nil, progname = nil)
      severity ||= UNKNOWN
      return true if @logdev.nil? || severity < level

      @mon.synchronize do
        # When using logger.info('msg'), Ruby Logger puts it in progname
        # When using logger.add(severity, 'msg'), it's in message
        actual_message = message || progname
        payload = normalize_message(actual_message)

        # Skip if normalize_message returned nil (empty/nil messages)
        return true if payload.nil?

        # Add to request context if we're in a request
        if defined?(RequestContext) && RequestContext.in_request?
          RequestContext.add_log(payload)
        end

        # Format and write to STDOUT
        formatted = @formatter.call(severity, Time.now, nil, payload)
        @logdev.write(formatted + "\n")

        # Broadcast to AppSignal if configured
        if @broadcast_logger
          # Build descriptive plaintext message for readability in log list
          msg = build_appsignal_message(payload)
          # Send all payload fields as searchable attributes
          attributes = payload

          # Map severity to AppSignal logger method
          case severity
          when ::Logger::FATAL then @broadcast_logger.fatal(msg, attributes)
          when ::Logger::ERROR then @broadcast_logger.error(msg, attributes)
          when ::Logger::WARN then @broadcast_logger.warn(msg, attributes)
          when ::Logger::INFO then @broadcast_logger.info(msg, attributes)
          when ::Logger::DEBUG then @broadcast_logger.debug(msg, attributes)
          else @broadcast_logger.info(msg, attributes)
          end
        end
      end

      true
    end

    private

    def build_appsignal_message(payload)
      # Build Rails-style human-readable message for AppSignal log list
      # Example: GET "/path" by Controller#action as HTML - 200 OK in 79ms
      if payload[:method] && payload[:path]
        parts = []

        # Method and path with quotes
        parts << "#{payload[:method]} \"#{payload[:path]}\""

        # Controller and action
        if payload[:controller] && payload[:action]
          parts << "by #{payload[:controller]}##{payload[:action]}"
        end

        # Format
        if payload[:format]
          parts << "as #{payload[:format].upcase}"
        end

        # Status with OK/Error text
        if payload[:status]
          status_text = if payload[:status] >= 500
            "Error"
          elsif payload[:status] >= 400
            "Client Error"
          else
            (payload[:status] >= 300) ? "Redirect" : "OK"
          end
          parts << "- #{payload[:status]} #{status_text}"
        end

        # Duration
        if payload[:duration_ms]
          parts << "in #{payload[:duration_ms].round(0)}ms"
        end

        parts.join(" ")
      else
        # Other logs: use the message field
        payload[:msg] || payload["msg"] || "Log"
      end
    end

    def normalize_message(message)
      case message
      when Hash
        message
      when String
        # Skip empty strings (Rails internal logging)
        return nil if message.strip.empty?
        {msg: message}
      when Exception
        {
          msg: message.message,
          error_class: message.class.name,
          backtrace: message.backtrace&.first(backtrace_limit)
        }
      when nil
        # Skip nil messages (Rails internal logging)
        nil
      else
        {msg: message.to_s}
      end
    end

    def default_formatter
      format = Rails.application.config.logmason.format
      case format
      when :logfmt
        Formatters::Logfmt.new
      else
        Formatters::Json.new
      end
    end

    def backtrace_limit
      Rails.application.config.logmason.backtrace_lines || 10
    end
  end
end
