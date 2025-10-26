# frozen_string_literal: true

require_relative "lib/logmason/version"

Gem::Specification.new do |spec|
  spec.name = "logmason"
  spec.version = Logmason::VERSION
  spec.authors = ["Matt Lins"]
  spec.email = ["your-email@example.com"]  # Update with actual email

  spec.summary = "Structured logging for Rails applications"
  spec.description = "Logmason provides structured JSON/LOGFMT logging for Rails with request context tracking, sensitive data filtering, and optional AppSignal integration."
  spec.homepage = "https://github.com/mlins/logmason"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mlins/logmason"

  spec.files = Dir[
    "lib/**/*",
    "LICENSE.txt",
    "README.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
end
