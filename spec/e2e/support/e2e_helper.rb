# frozen_string_literal: true

require_relative "gem_repo"
require_relative "project"

module E2E
  # Shared setup for the E2E specs: a fresh project per example.
  module Helpers
    def project
      @project ||= Project.new
    end

    # The line Runner prints before running a command against a secondary gemfile
    def header(gemfile, command)
      "== bundle_matrix: #{gemfile} -> bundle #{command}"
    end
  end
end

RSpec.configure do |config|
  config.include(E2E::Helpers, :e2e)
  config.after(:each, :e2e) { @project&.cleanup }
  config.after(:suite) { E2E::GemRepo.cleanup }
end
