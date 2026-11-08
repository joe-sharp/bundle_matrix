# frozen_string_literal: true

module BundleMatrix
  # Finds the secondary gemfiles that follow the main Gemfile.
  class Discovery
    # The gemfile a matrix.paths directory contributes, in Bundler's order
    DIRECTORY_GEMFILES = %w[gems.rb Gemfile].freeze

    # default_gemfile is the main gemfile's file name in root; it is never returned, whatever its name
    def initialize(root, paths, default_gemfile:)
      @root = Pathname(root).expand_path
      @paths = paths
      @default_gemfile = default_gemfile
    end

    # @return [Array<Pathname>] sorted, unique, excluding the main gemfile
    def gemfiles
      found = glob("*.gemfile") + glob("gemfiles/*.gemfile") + configured_gemfiles

      found.map(&:expand_path).uniq.sort.reject { |path| main_gemfile?(path) }
    end

    private

    def default_gemfile_path
      @root.join(@default_gemfile)
    end

    # Compares files, not paths, so a symlink to the main gemfile is excluded too
    def main_gemfile?(path)
      File.identical?(path, default_gemfile_path)
    end

    # Patterns are relative to the root, so glob characters in the project's own path are not special
    def glob(pattern)
      Dir.glob(pattern, base: @root.to_s).map { |match| @root.join(match) }
    end

    def configured_gemfiles
      @paths.flat_map do |entry|
        found = glob(entry).flat_map { |match| gemfiles_at(match) }
        Bundler.ui.warn("bundle_matrix: matrix.paths entry #{entry.inspect} matched no Gemfile") if found.empty?
        found
      end
    end

    def gemfiles_at(path)
      if path.directory?
        gemfile = DIRECTORY_GEMFILES.map { |name| path.join(name) }.find(&:file?)
        gemfile ? [gemfile] : []
      elsif path.file? && path.basename.to_s.match?(/(gemfile|\Agems\.rb)\z/i)
        [path]
      else
        []
      end
    end
  end
end
