# frozen_string_literal: true

RSpec.describe(BundleMatrix::Runner) do
  let(:root) { Pathname("/project") }
  let(:ci) { root.join("ci.gemfile") }
  let(:rails7) { root.join("gemfiles", "rails7.gemfile") }
  let(:runner) { described_class.new(root) }
  let(:child_envs) { [] }
  let(:broken) { BundleMatrix::Planner::Plan.new(invocation: nil, notes: [], error: "Gemfile syntax error") }

  def plan(argv, notes = [], locked_bundler: nil)
    BundleMatrix::Planner::Plan.new(
      invocation: argv && BundleMatrix::Invocation.parse(argv), notes: notes, locked_bundler: locked_bundler
    )
  end

  before do
    allow(Bundler.ui).to receive(:info)
    allow(Bundler.ui).to receive(:warn)
    allow(Bundler.ui).to receive(:error)
    allow(Bundler.settings).to receive(:[]).and_call_original
    allow(Bundler.settings).to receive(:[]).with(:version).and_return(nil)
    allow(BundleMatrix::ProjectSettings).to receive(:env).and_return({})
    allow(Bundler).to receive(:unbundled_system) { |env, *| child_envs << env }.and_return(true)
  end

  it "runs each gemfile through the bundled launcher, from that gemfile's directory" do
    runner.run(rails7 => plan(%w[install --jobs 4]))

    env = hash_including("BUNDLE_GEMFILE" => rails7.to_s, "BUNDLE_MATRIX_ACTIVE" => "1")
    expect(Bundler).to have_received(:unbundled_system)
      .with(env, Gem.ruby, described_class::BUNDLE, "install", "--jobs", "4", chdir: rails7.dirname.to_s)
  end

  it "prints a header naming each gemfile and the command run against it" do
    runner.run(rails7 => plan(%w[install --jobs 4]))

    expect(Bundler.ui).to have_received(:info)
      .with("== bundle_matrix: gemfiles/rails7.gemfile -> bundle install --jobs 4")
  end

  it "launches through RubyGems, so each gemfile gets its lockfile's Bundler version" do
    expect(File.read(described_class::BUNDLE)).to include('activate_and_load_bin_path("bundler", "bundle"')
  end

  it "clears BUNDLER_VERSION so it does not hold every gemfile to one version" do
    runner.run(ci => plan(%w[install]))

    expect(child_envs.first).to include("BUNDLER_VERSION" => nil)
  end

  it "passes on the project's settings, but sets the gemfile itself" do
    allow(BundleMatrix::ProjectSettings).to receive(:env).with(root)
      .and_return("BUNDLE_FROZEN" => "true", "BUNDLE_GEMFILE" => root.join("Gemfile").to_s)

    runner.run(ci => plan(%w[install]))

    expect(child_envs.first).to include("BUNDLE_FROZEN" => "true", "BUNDLE_GEMFILE" => ci.to_s)
  end

  it "prints a plan's notes and does not run a skipped plan", :aggregate_failures do
    runner.run(ci => plan(nil, ["skipped, no rails here"]))

    expect(Bundler.ui).to have_received(:info).with("== bundle_matrix: ci.gemfile: skipped, no rails here")
    expect(Bundler).not_to have_received(:unbundled_system)
  end

  it "runs every gemfile and then raises naming each that failed", :aggregate_failures do
    allow(Bundler).to receive(:unbundled_system).and_return(false, false)

    expect { runner.run(ci => plan(%w[install]), rails7 => plan(%w[install])) }
      .to raise_error(BundleMatrix::Error, "bundle_matrix: failed for ci.gemfile, gemfiles/rails7.gemfile")
    expect(Bundler).to have_received(:unbundled_system).twice
  end

  it "reports a gemfile that could not be planned as an error, and still runs the others", :aggregate_failures do
    expect { runner.run(ci => broken, rails7 => plan(%w[install])) }
      .to raise_error(BundleMatrix::Error, "bundle_matrix: failed for ci.gemfile")
    message = "== bundle_matrix: ci.gemfile: could not plan: Gemfile syntax error"
    expect(Bundler.ui).to have_received(:error).with(message)
    expect(Bundler.ui).not_to have_received(:info).with(a_string_including("could not plan"))
    expect(Bundler).to have_received(:unbundled_system).once
  end

  it "stops at a gemfile that could not be planned with fail_fast", :aggregate_failures do
    runner = described_class.new(root, fail_fast: true)
    allow(Bundler).to receive(:unbundled_system).and_return(true)

    expect { runner.run(ci => broken, rails7 => plan(%w[install])) }.to raise_error(BundleMatrix::Error)
    expect(Bundler).not_to have_received(:unbundled_system)
  end

  it "stops at the first failure with fail_fast", :aggregate_failures do
    runner = described_class.new(root, fail_fast: true)
    allow(Bundler).to receive(:unbundled_system).and_return(false)

    expect { runner.run(ci => plan(%w[install]), rails7 => plan(%w[install])) }
      .to raise_error(BundleMatrix::Error, "bundle_matrix: failed for ci.gemfile")
    expect(Bundler).to have_received(:unbundled_system).once
  end

  context "when a gemfile's lockfile names a different Bundler" do
    let(:suggestion) do
      "bundle_matrix: run `bundle update --bundler` to update Bundler in every lockfile, " \
        "or `bundle config set matrix.bundler_warnings false` to silence these warnings"
    end

    def other_bundler_plan(version)
      plan(%w[install], locked_bundler: Gem::Version.new(version))
    end

    it "warns with both versions for each such gemfile, then suggests updating once", :aggregate_failures do
      runner.run(ci => other_bundler_plan("2.5.23"), rails7 => other_bundler_plan("2.4.22"))

      expect(Bundler.ui).to have_received(:warn)
        .with("bundle_matrix: ci.gemfile uses Bundler 2.5.23, the main Gemfile uses #{Bundler::VERSION}")
      expect(Bundler.ui).to have_received(:warn)
        .with("bundle_matrix: gemfiles/rails7.gemfile uses Bundler 2.4.22, the main Gemfile uses #{Bundler::VERSION}")
      expect(Bundler.ui).to have_received(:warn).with(suggestion).once
    end

    it "still suggests updating when a gemfile fails", :aggregate_failures do
      allow(Bundler).to receive(:unbundled_system).and_return(false)

      expect { runner.run(ci => other_bundler_plan("2.5.23")) }.to raise_error(BundleMatrix::Error)
      expect(Bundler.ui).to have_received(:warn).with(suggestion)
    end

    it "does not warn when the lockfile names the running Bundler" do
      runner.run(ci => plan(%w[install], locked_bundler: Gem::Version.new(Bundler::VERSION)))

      expect(Bundler.ui).not_to have_received(:warn)
    end

    it "does not warn or suggest updating for a plan without a lockfile" do
      runner.run(ci => plan(%w[install]))

      expect(Bundler.ui).not_to have_received(:warn)
    end

    it "does not warn when bundler_warnings is off" do
      described_class.new(root, bundler_warnings: false).run(ci => other_bundler_plan("2.5.23"))

      expect(Bundler.ui).not_to have_received(:warn)
    end

    it "warns when the version setting is lockfile, as well as when it is unset", :aggregate_failures do
      allow(Bundler.settings).to receive(:[]).with(:version).and_return("lockfile")

      runner.run(ci => other_bundler_plan("2.5.23"))

      expect(Bundler.ui).to have_received(:warn).with(a_string_including("uses Bundler 2.5.23"))
    end

    it "does not warn when the version setting keeps every gemfile on the main Bundler", :aggregate_failures do
      %w[system 4.0.24].each do |setting|
        allow(Bundler.settings).to receive(:[]).with(:version).and_return(setting)

        runner.run(ci => other_bundler_plan("2.5.23"))
      end

      expect(Bundler.ui).not_to have_received(:warn)
    end
  end
end
