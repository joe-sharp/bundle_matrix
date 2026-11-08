# frozen_string_literal: true

require "rubygems/indexer"
require "rubygems/package"

module E2E
  # A local gem server on disk, so the suite resolves real versions without the network.
  module GemRepo
    # name => { version => runtime dependencies }
    GEMS = {
      "harry" => { "1.0.0" => {}, "1.0.1" => {}, "1.1.0" => {}, "2.0.0" => {} },
      "hermoine" => { "1.0.0" => {}, "1.1.0" => { "harry" => ">= 1.1" } },
      "ron" => { "1.0.0" => {}, "1.2.0" => { "harry" => ">= 2.0" } }
    }.freeze

    def self.uri
      "file://#{dir}"
    end

    def self.dir
      @dir ||= build
    end

    def self.cleanup
      FileUtils.rm_rf(@dir) if @dir
      @dir = nil
    end

    def self.build
      dir = Dir.mktmpdir("bundle_matrix-gems")
      gems_dir = File.join(dir, "gems")
      FileUtils.mkdir_p(gems_dir)

      Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
        Dir.chdir(gems_dir) do
          GEMS.each do |name, versions|
            versions.each { |version, deps| Gem::Package.build(spec(name, version, deps)) }
          end
        end
        Gem::Indexer.new(dir).generate_index
      end
      dir
    end

    def self.spec(name, version, deps)
      Gem::Specification.new do |s|
        s.name = name
        s.version = version
        s.summary = "Fixture gem for the bundle_matrix E2E suite"
        s.authors = ["bundle_matrix"]
        s.homepage = "https://example.com/#{name}"
        s.license = "MIT"
        s.required_ruby_version = ">= 3.2"
        s.files = []
        deps.each { |dep, requirement| s.add_dependency(dep, requirement) }
      end
    end
    private_class_method :build, :spec
  end
end
