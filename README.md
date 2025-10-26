# Logmason

Structured logging for Rails applications with JSON/LOGFMT output, request context tracking, and optional monitoring integration.

## Features

- **Structured Output**: JSON or LOGFMT formats for machine-readable logs
- **Request Context Tracking**: Automatic correlation of logs within a request
- **Sensitive Data Filtering**: Configurable filtering of passwords, tokens, secrets
- **Rails Event Subscribers**: Track database queries, cache hits/misses, exceptions
- **Broadcast Logger Support**: Send logs to external services (e.g., AppSignal)
- **Auto-Configuration**: Railtie provides sensible defaults, minimal setup required

## Requirements

- Ruby 3.0+
- Rails 7.0+

## Installation

Add to your `Gemfile`:

```ruby
gem 'logmason', git: 'https://github.com/mlins/logmason.git'
```

Then run:

```bash
bundle install
```

That's it! Logmason auto-configures via Railtie and enables structured logging in production by default.

## Configuration

Logmason auto-configures with sensible defaults. For production-only usage, put all config in `config/environments/production.rb`:

```ruby
# config/environments/production.rb

# Enable structured logging
config.logmason.enabled = true

# Output format for STDOUT (:json or :logfmt)
config.logmason.format = :logfmt

# Sensitive keys to filter from logs (optional - has good defaults)
# config.logmason.filter_keys = [:password, :token, :secret, :api_key]

# Exception backtrace line limit (optional - defaults to 10)
# config.logmason.backtrace_lines = 10
```

**Note:** The `format` setting only affects STDOUT output (Docker logs, Kamal logs, etc). AppSignal always receives logs in a custom human-readable format optimized for its interface.

All configuration is optional except `enabled`. Defaults work for most use cases.

## AppSignal Integration

AppSignal is **automatically detected** in production. If the `appsignal` gem is installed and `Appsignal` is defined, logmason automatically creates a broadcast logger.

**No configuration needed!** Just:
1. Add `gem 'appsignal'` to your Gemfile
2. Enable logmason in production
3. Logs automatically flow to both STDOUT and AppSignal

Logmason sends:
- **STDOUT**: Structured logs in your chosen format (JSON or LOGFMT)
- **AppSignal**: Human-readable messages with searchable attributes (custom format)
- **Both**: Include full request context for correlation

### Manual Broadcast Logger (Optional)

To use a custom broadcast logger instead of auto-detected AppSignal:

```ruby
# config/environments/production.rb
config.logmason.broadcast_logger = MyCustomLogger.new
```

## Output Format Examples

### JSON Format

```json
{
  "time": "2025-10-26T12:34:56.789012Z",
  "level": "INFO",
  "msg": "Request",
  "method": "GET",
  "path": "/tasks",
  "controller": "TasksController",
  "action": "index",
  "format": "html",
  "status": 200,
  "duration_ms": 45.23,
  "request_id": "abc-123",
  "user_id": 42,
  "db_queries": 3,
  "db_duration_ms": 12.45,
  "view_runtime_ms": 18.67
}
```

### LOGFMT Format

```
time=2025-10-26T12:34:56.789012Z level=INFO msg=Request method=GET path=/tasks controller=TasksController action=index format=html status=200 duration_ms=45.23 request_id=abc-123 user_id=42 db_queries=3 db_duration_ms=12.45 view_runtime_ms=18.67
```

## Migration from StructuredLogger

If migrating from a previous `StructuredLogger` implementation:

1. **Remove old initializer**: Delete `config/initializers/structured_logger.rb`

2. **Update config namespace**: Change `config.structured_logger.*` to `config.logmason.*` in `config/application.rb`

3. **Remove manual require**: Delete any `require_relative "../lib/structured_logger"` lines

4. **Update Gemfile**: Add `gem 'logmason'` and remove local file references

5. **Remove old files**: Delete `lib/structured_logger/` directory

## How It Works

### Request Context

Logmason uses Rack middleware to track request context in thread-local storage:

- Request ID, start time, user ID
- Database query counts and duration
- Cache hit/miss counts
- All logs during request include request_id for correlation

### Event Subscribers

Logmason subscribes to Rails instrumentation events:

- `process_action.action_controller` - Request completion with full metrics
- `sql.active_record` - Database query tracking
- `cache_read.active_support` - Cache hit/miss tracking
- Exceptions - Automatic error logging with backtrace

### Sensitive Data Filtering

Configurable keys are filtered from logs:

- Default: `:password`, `:password_confirmation`, `:token`, `:secret`, `:api_key`
- HTTP headers: `authorization`, `cookie`, `set-cookie`
- Filtered values replaced with `"[FILTERED]"`

## Development

Logmason is disabled by default in development and test environments to preserve Rails' colorized, multi-line logging.

To enable in development:

```ruby
# config/environments/development.rb
config.logmason.enabled = true
```

## License

MIT License - see LICENSE.txt

## Contributing

This is currently a private gem. If you encounter issues, please open an issue on GitHub.
