# frozen_string_literal: true

require_relative "support/e2e_helper"

RSpec.describe("bundle add", :e2e) do
  before do
    project.gemfile("Gemfile", %(gem "hermoine", "1.0.0"\n))
    project.gemfile("ci.gemfile", %(gem "hermoine", "1.0.0"\n))
    project.gemfile("gemfiles/rails.gemfile", %(gem "harry"\n))
    project.bundle!("install")
  end

  def declarations(gemfile, name)
    project.read(gemfile).lines.grep(/^\s*gem "#{name}"/)
  end

  # rubocop:disable-next RSpec/ExampleLength
  it "adds the gem to every gemfile and locks it", :aggregate_failures do
    project.bundle!("add", "ron")

    expect(declarations("Gemfile", "ron").size).to eq(1)
    expect(declarations("ci.gemfile", "ron").size).to eq(1)
    expect(declarations("gemfiles/rails.gemfile", "ron").size).to eq(1)
    expect(project.locked("ci.gemfile")).to include("ron" => "1.2.0")
    expect(project.locked("gemfiles/rails.gemfile")).to include("ron" => "1.2.0", "harry" => "2.0.0")
  end

  # rubocop:disable-next RSpec/ExampleLength
  it "fails naming a secondary gemfile that fails, and keeps the gem in the main Gemfile", :aggregate_failures do
    project.gemfile("gemfiles/rails.gemfile", %(gem "harry", "~> 1.0"\n))

    result = project.bundle("add", "ron", "--version", "1.2.0")

    expect(result).not_to be_success
    expect(result.stderr).to include("bundle_matrix: failed for gemfiles/rails.gemfile")
    expect(declarations("Gemfile", "ron").size).to eq(1)
    expect(project.locked("ci.gemfile")).to include("ron" => "1.2.0")
  end

  context "when the run does not fan out" do
    let(:secondaries) { %w[ci.gemfile gemfiles/rails.gemfile] }

    def snapshot
      secondaries.flat_map { |gemfile| [project.read(gemfile), project.read("#{gemfile}.lock")] }
    end

    it "leaves every secondary gemfile untouched when the main add fails", :aggregate_failures do
      before = snapshot

      result = project.bundle("add", "missing_gem")

      expect(result).not_to be_success
      expect(result.output).not_to include("== bundle_matrix")
      expect(snapshot).to eq(before)
    end

    # Bundler fires no after-install hook when nothing is installed
    it "does nothing with --skip-install", :aggregate_failures do
      before = snapshot

      output = project.bundle!("add", "ron", "--skip-install").output

      expect(output).not_to include("== bundle_matrix")
      expect(declarations("Gemfile", "ron").size).to eq(1)
      expect(snapshot).to eq(before)
    end
  end
end
