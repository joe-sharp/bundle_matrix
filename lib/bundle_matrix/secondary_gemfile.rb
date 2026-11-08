# frozen_string_literal: true

module BundleMatrix
  # A secondary gemfile, and what its lockfile and declarations say about it.
  class SecondaryGemfile
    attr_reader :path

    def initialize(path)
      @path = Pathname(path).expand_path
    end

    # Bundler locks a gems.rb in gems.locked, and every other gemfile in <gemfile>.lock
    def lockfile
      return path.sub_ext(".locked") if path.basename.to_s == "gems.rb"

      Pathname("#{path}.lock")
    end

    def locked?
      lockfile.file?
    end

    # The Bundler this gemfile's lockfile names in BUNDLED WITH, nil without a lockfile
    def bundler_version
      locked&.bundler_version
    end

    # Empty without a lockfile
    def lock_names
      @lock_names ||= (locked&.specs || []).map(&:name).uniq
    end

    def declared_names
      declared.map(&:name)
    end

    def declared_groups
      declared.flat_map(&:groups).map(&:to_s).uniq
    end

    private

    # nil when this gemfile has no lockfile yet. Bundler.locked_gems only reads the main Gemfile's lockfile,
    # so LockfileParser, which is not a plugin API, reads this one.
    def locked
      return @locked if defined?(@locked)

      @locked = locked? ? Bundler::LockfileParser.new(lockfile.read) : nil
    end

    # Dependencies declared by this gemfile, including those pulled in by eval_gemfile.
    # Bundler.definition only describes the main Gemfile, so Dsl, which is not a plugin API, evaluates this one.
    def declared
      @declared ||= Bundler::Dsl.new.tap { |dsl| dsl.eval_gemfile(path) }.dependencies
    end
  end
end
