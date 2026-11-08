# frozen_string_literal: true

module BundleMatrix
  VERSION = "0.1.0"

  # The oldest Bundler the plugin runs under. The gemspec requires it, and nothing newer is refused.
  # It is where Bundler::SharedHelpers.relative_path_to, which Planner uses, first appeared.
  MIN_BUNDLER = "2.6.9"

  # The Bundler versions the Appraisals test. The hook warns outside this range, not the gemspec.
  # The `.a` keeps 4.2 prereleases out too; raise it once a new Bundler minor has been tested.
  TESTED_BUNDLER = Gem::Requirement.new(">= #{MIN_BUNDLER}", "< 4.2.a")
end
