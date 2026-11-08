# frozen_string_literal: true

require "bundler"
require_relative "bundle_matrix/version"
require_relative "bundle_matrix/config"
require_relative "bundle_matrix/project_settings"
require_relative "bundle_matrix/discovery"
require_relative "bundle_matrix/argv_parser"
require_relative "bundle_matrix/invocation"
require_relative "bundle_matrix/secondary_gemfile"
require_relative "bundle_matrix/planner"
require_relative "bundle_matrix/runner"
require_relative "bundle_matrix/hook"

# A Bundler plugin that repeats `install`, `update` and `add` against every secondary gemfile in a project.
module BundleMatrix
  # Raised after the matrix run, when one or more secondary gemfiles failed
  class Error < Bundler::BundlerError
    status_code(1)
  end
end
