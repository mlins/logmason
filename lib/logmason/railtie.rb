# frozen_string_literal: true

module Logmason
  class Railtie < Rails::Railtie
    config.logmason = ActiveSupport::OrderedOptions.new

    # Set defaults
    config.logmason.format = :json
    config.logmason.filter_keys = [:password, :password_confirmation, :token, :secret, :api_key]
    config.logmason.backtrace_lines = 10
    config.logmason.broadcast_logger = nil
    config.logmason.enabled = nil  # Auto-detect based on environment

    initializer "logmason.configure_logger", before: :initialize_logger do |app|
      # Auto-enable in production, disable elsewhere (unless explicitly set)
      enabled = app.config.logmason.enabled
      enabled = Rails.env.production? if enabled.nil?

      next unless enabled

      # Create broadcast logger if configured (e.g., AppSignal)
      broadcast_logger = app.config.logmason.broadcast_logger

      # Determine formatter based on config
      formatter = case app.config.logmason.format
      when :logfmt
        Logmason::Formatters::Logfmt.new
      else
        Logmason::Formatters::Json.new
      end

      # Replace Rails logger with Logmason logger
      Rails.logger = Logmason::Logger.new(
        formatter: formatter,
        broadcast_logger: broadcast_logger
      )

      # Insert middleware
      app.config.middleware.use Logmason::Middleware

      # Attach all event subscribers
      Logmason::Subscribers::ActionController.attach
      Logmason::Subscribers::ActiveRecord.attach
      Logmason::Subscribers::Cache.attach
      Logmason::Subscribers::Exception.attach
    end
  end
end
