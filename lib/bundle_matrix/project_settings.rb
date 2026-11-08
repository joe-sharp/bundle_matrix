# frozen_string_literal: true

module BundleMatrix
  # The project's settings that a child run would otherwise lose: its .bundle/config,
  # which a child doesn't read because it looks in its own gemfile's directory, and
  # the BUNDLE_* variables the user set, which Bundler.with_unbundled_env strips.
  # They are passed on as BUNDLE_* variables, so a gemfile's own .bundle/config still wins.
  # Settings#all and #locations are not a plugin API, so a Bundler release can change them.
  module ProjectSettings
    # Settings that point at the main Gemfile's own files; each child sets these itself
    MAIN_ONLY = %w[gemfile lockfile app_config bin_path].freeze

    # Settings holding a path relative to the project root, which a child would
    # otherwise resolve from its own directory
    PATHS = %w[path bin cache_path].freeze

    # @return [Hash{String => String}] BUNDLE_* variables for a child run
    def self.env(root)
      settings = Bundler.settings
      user_env = Bundler.original_env

      (settings.all - MAIN_ONLY).each_with_object({}) do |name, env|
        key = settings.key_for(name)
        # Bundler gives .bundle/config priority over the environment
        value = settings.locations(name)[:local] || user_env[key]
        next if value.nil?

        env[key] = PATHS.include?(name) ? File.expand_path(value.to_s, root) : value.to_s
      end
    end
  end
end
