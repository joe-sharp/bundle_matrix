# frozen_string_literal: true

module BundleMatrix
  VERSION = "0.1.0"

  # The Bundler versions the Appraisals test. The gemspec requires this range, and the hook warns outside it.
  # The lower bound is where Bundler::SharedHelpers.relative_path_to, which Planner uses, first appeared.
  # The `.a` keeps 4.2 prereleases out too; raise it once a new Bundler minor has been tested.
  TESTED_BUNDLER = Gem::Requirement.new(">= 2.6.9", "< 4.2.a")
end
