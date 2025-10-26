# frozen_string_literal: true

require_relative "logmason/version"
require_relative "logmason/formatters/base"
require_relative "logmason/formatters/json"
require_relative "logmason/formatters/logfmt"
require_relative "logmason/request_context"
require_relative "logmason/logger"
require_relative "logmason/middleware"
require_relative "logmason/subscribers/action_controller"
require_relative "logmason/subscribers/active_record"
require_relative "logmason/subscribers/cache"
require_relative "logmason/subscribers/exception"

module Logmason
  # Structured logging for Rails applications
end

# Load Railtie if Rails is present
require_relative "logmason/railtie" if defined?(Rails::Railtie)
