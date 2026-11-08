# frozen_string_literal: true

require_relative "support/e2e_helper"

RSpec.describe("bundle install", :e2e) do
  before do
    project.gemfile("Gemfile", %(gem "harry", "~> 1.0.0"\n))
    project.gemfile("ci.gemfile", %(gem "harry", "~> 1.0"\ngem "hermoine", "1.0.0"\n))
    project.gemfile("gemfiles/rails.gemfile", %(gem "ron", "1.0.0"\n))
  end

  context "when every gemfile resolves" do
    it "locks the main Gemfile and every secondary gemfile with its own gems", :aggregate_failures do
      project.bundle!("install")

      expect(project.locked("Gemfile")).to include("harry" => "1.0.1")
      expect(project.locked("ci.gemfile")).to eq("harry" => "1.1.0", "hermoine" => "1.0.0")
      expect(project.locked("gemfiles/rails.gemfile")).to eq("ron" => "1.0.0")
    end

    it "treats `bundle i` as install", :aggregate_failures do
      output = project.bundle!("i").output

      expect(output).to include(header("ci.gemfile", "install"))
      expect(project).to be_lockfile("ci.gemfile")
    end

    it "is idempotent" do
      project.bundle!("install")
      before = %w[Gemfile ci.gemfile gemfiles/rails.gemfile].map { |gemfile| project.read("#{gemfile}.lock") }

      project.bundle!("install")

      expect(%w[Gemfile ci.gemfile gemfiles/rails.gemfile].map { |gemfile| project.read("#{gemfile}.lock") })
        .to eq(before)
    end
  end

  # Bundler's own default_cli_command decides what a bare `bundle` runs, so these pin the plugin to it
  context "when bundle runs without a command" do
    it "fans out as install when default_cli_command is not set", :aggregate_failures do
      output = project.bundle!.output

      expect(output).to include(header("ci.gemfile", "install"))
      expect(project).to be_lockfile("ci.gemfile")
    end

    it "fans out as install for switches only, such as --jobs=4", :aggregate_failures do
      output = project.bundle!("--jobs=4").output

      expect(output).to include(header("ci.gemfile", "install --jobs=4"))
      expect(project).to be_lockfile("ci.gemfile")
    end

    it "fans out when default_cli_command is install" do
      project.config("default_cli_command", "install")

      project.bundle!

      expect(project).to be_lockfile("ci.gemfile")
    end

    it "does not fan out when default_cli_command is cli_help", :aggregate_failures do
      project.config("default_cli_command", "cli_help")

      project.bundle!

      expect(project).not_to be_lockfile("ci.gemfile")
      expect(project).not_to be_lockfile("gemfiles/rails.gemfile")
    end
  end

  it "also installs each Gemfile in the directories set by matrix.paths", :aggregate_failures do
    project.gemfile("engines/admin/Gemfile", %(gem "hermoine", "1.0.0"\n))
    project.config("matrix.paths", "engines/*")

    output = project.bundle!("install").output

    expect(output).to include(header("engines/admin/Gemfile", "install"))
    expect(project.locked("engines/admin/Gemfile")).to eq("hermoine" => "1.0.0")
  end

  # Each child runs from its own gemfile's directory, so Bundler would otherwise resolve these there
  context "with project settings" do
    it "resolves a relative path from the project root for every gemfile", :aggregate_failures do
      project.bundle!("install")

      expect(Dir.glob(project.root.join("vendor/bundle/ruby/*/gems/ron-1.0.0"))).not_to be_empty
      expect(project).not_to exist("gemfiles/vendor")
    end

    it "applies without to every gemfile", :aggregate_failures do
      project.gemfile("ci.gemfile", %(gem "harry", "~> 1.0"\ngroup :test do\n  gem "hermoine", "1.0.0"\nend\n))
      project.config("without", "test")

      project.bundle!("install")

      expect(project.locked("ci.gemfile")).to include("hermoine" => "1.0.0")
      expect(Dir.glob(project.root.join("vendor/bundle/ruby/*/gems/hermoine-*"))).to be_empty
    end
  end

  # rubocop:disable-next RSpec/ExampleLength
  it "runs the other gemfiles when a secondary gemfile fails, then fails naming it", :aggregate_failures do
    project.gemfile("ci.gemfile", %(gem "harry", "~> 9.0"\n))

    result = project.bundle("install")

    expect(result).not_to be_success
    expect(result.stderr).to include("bundle_matrix: failed for ci.gemfile")
    expect(project).to be_lockfile("Gemfile")
    expect(project).to be_lockfile("gemfiles/rails.gemfile")
  end

  # rubocop:disable-next RSpec/ExampleLength
  it "fails an out of date frozen secondary gemfile, and still runs the others", :aggregate_failures do
    project.bundle!("install")
    locked_before = project.read("ci.gemfile.lock")
    project.gemfile("ci.gemfile", %(gem "harry", "~> 1.0"\ngem "hermoine", "1.0.0"\ngem "ron", "1.0.0"\n))
    project.config("frozen", true)

    result = project.bundle("install")

    expect(result).not_to be_success
    expect(result.stderr).to include("bundle_matrix: failed for ci.gemfile")
    expect(result.output).to include(header("gemfiles/rails.gemfile", "install"))
    expect(project.read("ci.gemfile.lock")).to eq(locked_before)
  end

  context "when the run does not fan out" do
    it "does nothing when the main install fails", :aggregate_failures do
      project.gemfile("Gemfile", %(gem "harry", "~> 9.0"\n))

      result = project.bundle("install")

      expect(result).not_to be_success
      expect(result.output).not_to include("== bundle_matrix")
      expect(project).not_to be_lockfile("ci.gemfile")
    end

    it "does nothing when disabled", :aggregate_failures do
      project.config("matrix.disabled", true)

      output = project.bundle!("install").output

      expect(output).not_to include("== bundle_matrix")
      expect(project).not_to be_lockfile("ci.gemfile")
    end

    it "does nothing when BUNDLE_MATRIX__DISABLED is set", :aggregate_failures do
      output = project.bundle!("install", env: { "BUNDLE_MATRIX__DISABLED" => "1" }).output

      expect(output).not_to include("== bundle_matrix")
      expect(project).not_to be_lockfile("ci.gemfile")
    end

    # rubocop:disable-next RSpec/ExampleLength
    it "does nothing when BUNDLE_GEMFILE names a secondary gemfile", :aggregate_failures do
      project.bundle!("install")
      project.gemfile("gemfiles/rack.gemfile", %(gem "harry"\n))
      # Control run: the same command without BUNDLE_GEMFILE does fan out to rack.gemfile
      expect(project.bundle!("install").output).to include(header("gemfiles/rack.gemfile", "install"))
      project.root.join("gemfiles/rack.gemfile.lock").delete

      output = project.bundle!("install", env: { "BUNDLE_GEMFILE" => project.root.join("ci.gemfile").to_s }).output

      expect(output).not_to include("== bundle_matrix")
      expect(project).not_to be_lockfile("gemfiles/rack.gemfile")
    end
  end
end
