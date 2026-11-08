# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch                         # track branches as well as lines
    track_files "lib/**/*.rb"                       # report on these files, even if never loaded
    add_filter "/spec/"
    minimum_coverage line: 90, branch: 80           # SimpleCov 0.22 spelling of coverage :line / :branch minimums
    maximum_coverage_drop 1                         # fail if coverage drops more than 1 point from last run
  end
end

require "bundle_matrix"
require "fileutils"
require "tmpdir"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  # Stubs must name methods that exist, and examples must not depend on the order they run in
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.order = :random
  Kernel.srand(config.seed)
end
