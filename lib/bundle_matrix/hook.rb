# frozen_string_literal: true

module BundleMatrix
  # Called by Bundler after `install`, `update` or `add` has finished.
  module Hook
    ISSUES_URL = "https://github.com/joe-sharp/bundle_matrix/issues"

    def self.call(argv = ARGV)
      invocation = Invocation.parse(argv)
      return unless invocation && !secondary_run?

      config = Config.new
      return if config.disabled? || !default_gemfile?(config)

      root = Bundler.root
      gemfiles = Discovery.new(root, config.paths, default_gemfile: config.default_gemfile).gemfiles
      return if gemfiles.empty?

      warn_untested_bundler

      runner = Runner.new(root, fail_fast: config.fail_fast?, bundler_warnings: config.bundler_warnings?)
      runner.run(plans_for(invocation, gemfiles, root))
    end

    def self.plans_for(invocation, gemfiles, root)
      gemfiles.to_h do |gemfile|
        [gemfile, Planner.new(invocation, gemfile, root).plan]
      end
    end

    # Fan-out still runs under an untested Bundler, but asks to hear about anything that breaks
    def self.warn_untested_bundler
      return if TESTED_BUNDLER.satisfied_by?(Gem::Version.new(Bundler::VERSION))

      Bundler.ui.warn(
        "bundle_matrix: not tested with Bundler #{Bundler::VERSION}; " \
        "if anything goes wrong, please open an issue at #{ISSUES_URL}"
      )
    end

    def self.default_gemfile?(config)
      Bundler.default_gemfile.basename.to_s == config.default_gemfile
    end

    # Child runs set this, so they never fan out again
    def self.secondary_run?
      !ENV["BUNDLE_MATRIX_ACTIVE"].to_s.empty?
    end
    private_class_method :default_gemfile?, :secondary_run?, :plans_for, :warn_untested_bundler
    private_constant :ISSUES_URL
  end
end
