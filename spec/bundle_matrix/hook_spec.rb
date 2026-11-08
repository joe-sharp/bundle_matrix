# frozen_string_literal: true

RSpec.describe(BundleMatrix::Hook) do
  let(:root) { Pathname("/project") }
  let(:discovered) { [root.join("ci.gemfile"), root.join("gemfiles/rails7.gemfile")] }

  def config_double(**overrides)
    defaults = { disabled?: false, paths: [], fail_fast?: false, bundler_warnings?: true, default_gemfile: "Gemfile" }
    instance_double(BundleMatrix::Config, **defaults, **overrides)
  end

  before do
    allow(Bundler).to receive_messages(default_gemfile: root.join("Gemfile"), root: root)
    allow(Bundler.ui).to receive(:warn)
    allow(BundleMatrix::Runner).to receive(:new).and_return(instance_double(BundleMatrix::Runner, run: nil))
    allow(BundleMatrix::Discovery).to receive(:new).and_return(
      instance_double(BundleMatrix::Discovery, gemfiles: [root.join("ci.gemfile")])
    )
    allow(BundleMatrix::Planner).to receive(:new).and_return(instance_double(BundleMatrix::Planner, plan: :ci_plan))
    allow(BundleMatrix::Config).to receive(:new).and_return(config_double)
    stub_const("ENV", ENV.to_h.merge("BUNDLE_MATRIX_ACTIVE" => nil))
  end

  # The untested-Bundler warning, checked directly, since the hook only reaches it after finding gemfiles
  describe "the untested Bundler warning" do
    def warn_untested_bundler
      described_class.send(:warn_untested_bundler)
    end

    it "warns that a Bundler outside the tested range is untested, linking to the issue tracker" do
      stub_const("Bundler::VERSION", "4.2.0")

      warn_untested_bundler

      expect(Bundler.ui).to have_received(:warn).with(
        "bundle_matrix: not tested with Bundler 4.2.0; " \
        "if anything goes wrong, please open an issue at https://github.com/joe-sharp/bundle_matrix/issues"
      )
    end

    it "treats a 4.2 prerelease as untested" do
      stub_const("Bundler::VERSION", "4.2.0.beta1")

      warn_untested_bundler

      expect(Bundler.ui).to have_received(:warn)
    end

    it "does not warn under a tested Bundler" do
      %w[2.6.9 4.1.0.beta3].each do |version|
        stub_const("Bundler::VERSION", version)

        warn_untested_bundler
      end

      expect(Bundler.ui).not_to have_received(:warn)
    end

    it "warns before fanning out, when the running Bundler is untested", :aggregate_failures do
      stub_const("Bundler::VERSION", "4.2.0")

      described_class.call(%w[install])

      expect(Bundler.ui).to have_received(:warn).with(a_string_including("not tested with Bundler 4.2.0"))
      expect(BundleMatrix::Runner).to have_received(:new)
    end
  end

  it "does nothing when running inside a secondary run" do
    stub_const("ENV", ENV.to_h.merge("BUNDLE_MATRIX_ACTIVE" => "1"))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).not_to have_received(:new)
  end

  it "does nothing when the main Gemfile is not the default gemfile" do
    allow(Bundler).to receive(:default_gemfile).and_return(root.join("ci.gemfile"))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).not_to have_received(:new)
  end

  it "fans out from an overridden default gemfile", :aggregate_failures do
    allow(Bundler).to receive(:default_gemfile).and_return(root.join("gems.rb"))
    allow(BundleMatrix::Config).to receive(:new).and_return(config_double(default_gemfile: "gems.rb"))

    described_class.call(%w[install])

    expect(BundleMatrix::Discovery).to have_received(:new).with(root, [], default_gemfile: "gems.rb")
    expect(BundleMatrix::Runner).to have_received(:new)
  end

  it "does nothing from Gemfile when the default gemfile is overridden" do
    allow(BundleMatrix::Config).to receive(:new).and_return(config_double(default_gemfile: "gems.rb"))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).not_to have_received(:new)
  end

  it "does nothing when disabled" do
    allow(BundleMatrix::Config).to receive(:new).and_return(instance_double(BundleMatrix::Config, disabled?: true))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).not_to have_received(:new)
  end

  it "does nothing for commands other than install, update and add" do
    described_class.call(%w[exec rspec])

    expect(BundleMatrix::Runner).not_to have_received(:new)
  end

  it "does nothing when there are no secondary gemfiles" do
    allow(BundleMatrix::Discovery).to receive(:new).and_return(instance_double(BundleMatrix::Discovery, gemfiles: []))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).not_to have_received(:new)
  end

  {
    "install" => %w[install],
    "update" => %w[update --all],
    "add" => %w[add rack]
  }.each do |command, argv|
    it "plans every discovered gemfile for #{command}", :aggregate_failures do
      allow(BundleMatrix::Discovery).to receive(:new)
        .and_return(instance_double(BundleMatrix::Discovery, gemfiles: discovered))

      described_class.call(argv)

      discovered.each do |gemfile|
        expect(BundleMatrix::Planner).to have_received(:new)
          .with(having_attributes(command: command), gemfile, root)
      end
    end
  end

  it "hands every gemfile's plan to the runner, with fail_fast from the config", :aggregate_failures do
    runner = instance_double(BundleMatrix::Runner, run: nil)
    allow(BundleMatrix::Runner).to receive(:new).and_return(runner)

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).to have_received(:new).with(root, fail_fast: false, bundler_warnings: true)
    expect(runner).to have_received(:run).with(root.join("ci.gemfile") => :ci_plan)
  end

  it "passes fail_fast through to the runner when the config enables it" do
    allow(BundleMatrix::Config).to receive(:new).and_return(config_double(fail_fast?: true))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).to have_received(:new).with(root, fail_fast: true, bundler_warnings: true)
  end

  it "passes bundler_warnings through to the runner when the config turns it off" do
    allow(BundleMatrix::Config).to receive(:new).and_return(config_double(bundler_warnings?: false))

    described_class.call(%w[install])

    expect(BundleMatrix::Runner).to have_received(:new).with(root, fail_fast: false, bundler_warnings: false)
  end
end
