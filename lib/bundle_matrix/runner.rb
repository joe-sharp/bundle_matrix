# frozen_string_literal: true

module BundleMatrix
  # Runs each planned command in a separate `bundle` process. Bundler keeps
  # global state, so the secondary gemfiles can't be run in this process.
  class Runner
    # Launched like a plain `bundle`, so RubyGems and Bundler pick each gemfile's Bundler version.
    # __dir__ is only nil inside eval, which Steep can't rule out.
    BUNDLE = File.expand_path("bundle", __dir__) # steep:ignore

    # bundler_warnings is false when the matrix.bundler_warnings setting turns off the Bundler version warnings
    def initialize(root, fail_fast: false, bundler_warnings: true)
      @root = Pathname(root).expand_path
      @fail_fast = fail_fast
      @bundler_warnings = bundler_warnings
    end

    # @param plans [Hash{Pathname => Planner::Plan}]
    def run(plans)
      failures = []
      other_bundler = false

      plans.each do |gemfile, plan|
        label = gemfile.relative_path_from(@root)
        # Only a plan that runs carries a locked_bundler, so a skipped or unplannable one never sets this
        version = other_bundler_for(plan)
        other_bundler ||= version
        next if plan_passed?(gemfile, label, plan, version)

        failures << label
        break if @fail_fast
      end

      suggest_bundler_update if other_bundler
      return if failures.empty?

      raise Error, "bundle_matrix: failed for #{failures.join(", ")}"
    end

    private

    # @return [Boolean] true when the plan was skipped or its command succeeded
    def plan_passed?(gemfile, label, plan, other_bundler)
      if plan.failed?
        report_unplanned(label, plan.error)
        return false
      end

      plan.notes.each { |note| say(label, note) }
      # A plan that neither failed nor has a command was skipped
      invocation = plan.invocation
      return true unless invocation

      Bundler.ui.info("== bundle_matrix: #{label} -> bundle #{invocation.to_argv.join(" ")}")
      warn_other_bundler(label, other_bundler)
      success?(gemfile, invocation)
    end

    def say(label, message)
      Bundler.ui.info("== bundle_matrix: #{label}: #{message}")
    end

    # A gemfile that could not be planned is a failure, and the other gemfiles still run
    def report_unplanned(label, error)
      Bundler.ui.error("== bundle_matrix: #{label}: could not plan: #{error}")
    end

    # The Bundler a plan's lockfile switches to, when that is worth a warning; nil otherwise.
    # A child switches only when the `version` setting is lockfile, the default. With `system` or a pinned
    # version, every gemfile runs the same Bundler as the main one.
    def other_bundler_for(plan)
      version = plan.locked_bundler
      return unless version && @bundler_warnings && [nil, "lockfile"].include?(Bundler.settings[:version])

      version unless version == Gem::Version.new(Bundler::VERSION)
    end

    def warn_other_bundler(label, version)
      return unless version

      Bundler.ui.warn("bundle_matrix: #{label} uses Bundler #{version}, the main Gemfile uses #{Bundler::VERSION}")
    end

    def suggest_bundler_update
      Bundler.ui.warn(
        "bundle_matrix: run `bundle update --bundler` to update Bundler in every lockfile, " \
        "or `bundle config set matrix.bundler_warnings false` to silence these warnings"
      )
    end

    def success?(gemfile, invocation)
      Bundler.unbundled_system(
        child_env(gemfile), Gem.ruby, BUNDLE, *invocation.to_argv, chdir: gemfile.dirname.to_s
      ) == true
    end

    # BUNDLER_VERSION would hold every gemfile to one version, and it is left set in this
    # process when Bundler restarted itself for the main lockfile, so it is cleared.
    def child_env(gemfile)
      project_env.merge(
        "BUNDLE_GEMFILE" => gemfile.to_s,
        "BUNDLE_MATRIX_ACTIVE" => "1",
        "BUNDLER_VERSION" => nil
      )
    end

    def project_env
      @project_env ||= ProjectSettings.env(@root)
    end
  end
end
