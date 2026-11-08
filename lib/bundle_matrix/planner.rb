# frozen_string_literal: true

module BundleMatrix
  # Decides what to run against one secondary gemfile, given the command the
  # user ran on the main Gemfile.
  class Planner
    Plan = Data.define(:invocation, :notes, :error, :locked_bundler)

    # invocation is nil when the gemfile should be skipped; notes explain why; error is set when planning failed;
    # locked_bundler is the Bundler named in this gemfile's lockfile, set on every plan that runs a command
    class Plan
      def initialize(invocation:, notes:, error: nil, locked_bundler: nil)
        super
      end

      def failed?
        !error.nil?
      end

      def skipped?
        invocation.nil? && error.nil?
      end
    end

    # Install flags that only make sense for the main Gemfile, or that Bundler no longer accepts
    MAIN_ONLY_INSTALL_OPTIONS = %w[lockfile standalone path].freeze

    def initialize(invocation, gemfile, root)
      @invocation = invocation.without("gemfile")
      @gemfile = SecondaryGemfile.new(gemfile)
      @root = Pathname(root).expand_path
    end

    def plan
      case @invocation.command
      when "install" then install_plan(@invocation)
      when "update" then update_plan
      when "add" then add_plan
      else raise ArgumentError, "unknown command #{@invocation.command}"
      end
    rescue => e
      # One gemfile that can't be read must not stop the others, so its error is reported as its own failure
      Plan.new(invocation: nil, notes: [], error: e.message)
    end

    private

    def install_plan(invocation, notes = [])
      dropped = MAIN_ONLY_INSTALL_OPTIONS.select { |name| invocation.option?(name) }
      notes += dropped.map { |name| "--#{name} is not forwarded to other gemfiles" }
      run(invocation.without(*MAIN_ONLY_INSTALL_OPTIONS), notes)
    end

    def update_plan
      return run(@invocation) if full_update?(@invocation)
      return install_instead("no lockfile yet") unless @gemfile.locked?

      narrow_update(@invocation)
    end

    # Keeps only the named gems and groups that this gemfile's lockfile or dependencies know about
    def narrow_update(invocation)
      gems = invocation.gems & @gemfile.lock_names
      groups = narrow_groups(invocation)
      if unmatched?(invocation, gems, groups)
        return skip("none of #{requested(invocation).join(", ")} are in this gemfile")
      end

      run(invocation.with_gems(gems).replace_values("group", groups))
    end

    # Declared groups are only read when --group was given, because reading them evaluates the whole gemfile
    def narrow_groups(invocation)
      requested_groups = invocation.values("group")
      return [] if requested_groups.empty?

      requested_groups & @gemfile.declared_groups
    end

    # Named gems or groups were given, but none of them apply to this gemfile
    def unmatched?(invocation, gems, groups)
      requested(invocation).any? && gems.empty? && groups.empty? &&
        !invocation.option?("ruby") && !invocation.option?("bundler")
    end

    def requested(invocation)
      invocation.gems + invocation.values("group")
    end

    def add_plan
      declared = @gemfile.declared_names
      already = @invocation.gems & declared
      new_gems = @invocation.gems - declared
      notes = already.map { |name| "#{name} is already declared, not added again" }

      if new_gems.empty?
        return install_plan(@invocation.as("install"), notes + ["gems already declared, re-locking with install"])
      end

      run(rewrite_path(@invocation.with_gems(new_gems)), notes)
    end

    def full_update?(invocation)
      return true if invocation.option?("all")

      invocation.gems.empty? && invocation.values("source").empty? && invocation.values("group").empty? &&
        !invocation.option?("ruby") && !invocation.option?("bundler")
    end

    def install_instead(reason)
      install_plan(@invocation.as("install"), ["#{reason}, running install to create it"])
    end

    # A relative --path is written into the main Gemfile relative to the root,
    # so it has to be rewritten to be relative to this gemfile instead.
    def rewrite_path(invocation)
      return invocation unless invocation.option?("path")

      absolute = File.expand_path(invocation.values("path").first, @root)
      relative = Bundler::SharedHelpers.relative_path_to(absolute, from: @gemfile.path.dirname)
      invocation.replace_values("path", [relative])
    end

    def run(invocation, notes = [])
      Plan.new(invocation: invocation, notes: notes, locked_bundler: @gemfile.bundler_version)
    end

    def skip(reason)
      Plan.new(invocation: nil, notes: ["skipped, #{reason}"])
    end
  end
end
