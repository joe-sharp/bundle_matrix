# frozen_string_literal: true

require_relative "lib/bundle_matrix/version"

Gem::Specification.new do |spec|
  spec.name = "bundle_matrix"
  spec.version = BundleMatrix::VERSION
  spec.authors = ["Joe Sharp"]
  spec.email = ["joesharp13@gmail.com"]

  spec.summary = "Runs bundle install, update and add against every secondary gemfile too."
  spec.description = "A Bundler plugin. After install, update or add on the main Gemfile, it replays the same " \
                     "command, with the same flags, against *.gemfile files in the project root and gemfiles/, " \
                     "and any extra directories configured with matrix.paths."
  spec.homepage = "https://github.com/joe-sharp/bundle_matrix"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{BundleMatrix::VERSION}"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # Only the listed paths that are tracked in git go into the gem, so untracked files never get in.
  spec.files = IO.popen(
    %w[git ls-files -z -- lib sig plugins.rb README.md LICENSE.txt CHANGELOG.md],
    chdir: __dir__,
    err: IO::NULL
  ) do |ls|
    ls.readlines("\x0", chomp: true)
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # The plugin relies on Bundler internals that aren't a plugin API, so it only allows the tested range
  spec.add_dependency "bundler", *BundleMatrix::TESTED_BUNDLER.as_list

  # For more information and examples about making a new gem, check out our
  # guide at: https://guides.rubygems.org/make-your-own-gem/
end
