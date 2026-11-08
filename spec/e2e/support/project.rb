# frozen_string_literal: true

require "open3"
require "yaml"

module E2E
  # A throwaway project with the plugin declared in its main Gemfile. Commands run
  # in a real `bundle` process, isolated from the developer's own Bundler setup.
  class Project
    PLUGIN_ROOT = File.expand_path("../../..", __dir__)

    Result = Data.define(:stdout, :stderr, :status) do
      def success?
        status.success?
      end

      def output
        stdout + stderr
      end
    end

    attr_reader :root

    def initialize
      @root = Pathname(Dir.mktmpdir("bundle_matrix-project")).realpath
      @home = Pathname(Dir.mktmpdir("bundle_matrix-home"))
      # Every gemfile installs into the project's own vendor/bundle, never the developer's gems
      config("path", "vendor/bundle")
    end

    def cleanup
      FileUtils.rm_rf([@root, @home])
    end

    # Writes a gemfile using the fixture gem repo. The main Gemfile also declares the plugin.
    def gemfile(path, body = "")
      plugin = %w[Gemfile gems.rb].include?(path) ? %(plugin "bundle_matrix", path: "#{PLUGIN_ROOT}"\n) : ""
      write(path, %(source "#{GemRepo.uri}"\n#{plugin}#{body}))
    end

    # A gem on disk, for `path:` sources
    def path_gem(dir, name, version = "1.0.0")
      write(File.join(dir, "#{name}.gemspec"), <<~RUBY)
        Gem::Specification.new do |s|
          s.name = #{name.inspect}
          s.version = #{version.inspect}
          s.summary = "Path fixture gem"
          s.authors = ["bundle_matrix"]
          s.files = []
        end
      RUBY
    end

    def write(path, content)
      file = @root.join(path)
      file.dirname.mkpath
      file.write(content)
    end

    def read(path)
      @root.join(path).read
    end

    def exist?(path)
      @root.join(path).exist?
    end

    # Sets a value in .bundle/config, in the project root or next to a secondary gemfile
    def config(key, value, dir: ".")
      file = @root.join(dir, ".bundle", "config")
      settings = file.file? ? YAML.safe_load(file.read) : {}
      settings["BUNDLE_#{key.upcase.gsub(".", "__")}"] = value.to_s
      file.dirname.mkpath
      file.write(YAML.dump(settings))
    end

    # @return [Hash{String => String}] gem name => locked version, empty without a lockfile
    def locked(gemfile)
      lockfile = @root.join("#{gemfile}.lock")
      return {} unless lockfile.file?

      Bundler::LockfileParser.new(lockfile.read).specs.to_h { |spec| [spec.name, spec.version.to_s] }
    end

    def lockfile?(gemfile)
      @root.join("#{gemfile}.lock").file?
    end

    def bundle(*args, env: {})
      Bundler.with_unbundled_env do
        stdout, stderr, status = Open3.capture3(
          isolated_env.merge(env), Gem.ruby, BundleMatrix::Runner::BUNDLE, *args, chdir: @root.to_s
        )
        Result.new(stdout: stdout, stderr: stderr, status: status)
      end
    end

    # Like #bundle, but fails the example with Bundler's output when the command fails
    def bundle!(*args, env: {})
      bundle(*args, env: env).tap do |result|
        raise "bundle #{args.join(" ")} failed:\n#{result.output}" unless result.success?
      end
    end

    private

    def isolated_env
      {
        "HOME" => @home.to_s,
        "BUNDLE_USER_HOME" => @home.join(".bundle").to_s,
        "BUNDLE_GEMFILE" => nil,
        "BUNDLE_APP_CONFIG" => nil,
        "BUNDLER_VERSION" => nil,
        "BUNDLE_MATRIX_ACTIVE" => nil
      }
    end
  end
end
