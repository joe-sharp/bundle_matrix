# frozen_string_literal: true

module BundleMatrix
  # Reads the matrix.* settings, from `bundle config` or BUNDLE_MATRIX__* env vars.
  class Config
    TRUE_VALUES = %w[true 1 yes].freeze
    FALSE_VALUES = %w[false 0 no].freeze
    DEFAULT_GEMFILE = "Gemfile"

    # Extra directories (or globs) to search for a Gemfile, e.g. "engines/*,apps/admin".
    def paths
      Bundler.settings["matrix.paths"].to_s.split(",").map(&:strip).reject(&:empty?)
    end

    # The file name of the main gemfile in the project root, e.g. "gems.rb". Fan-out starts from it.
    def default_gemfile
      value = Bundler.settings["matrix.default_gemfile"].to_s.strip
      value.empty? ? DEFAULT_GEMFILE : value
    end

    def disabled?
      truthy?("matrix.disabled")
    end

    def fail_fast?
      truthy?("matrix.fail_fast")
    end

    # Warn when a gemfile runs a different Bundler from the main one; on unless set to false, 0 or no
    def bundler_warnings?
      !FALSE_VALUES.include?(Bundler.settings["matrix.bundler_warnings"].to_s.downcase)
    end

    private

    def truthy?(key)
      TRUE_VALUES.include?(Bundler.settings[key].to_s.downcase)
    end
  end
end
