# frozen_string_literal: true

RSpec.describe(BundleMatrix::Planner) do
  let(:root) { Pathname(Dir.mktmpdir("bundle_matrix_root")).realpath }
  let(:gemfile) { root.join("gemfiles", "old.gemfile") }

  after { FileUtils.remove_entry(root) }

  def write(path, contents)
    path.dirname.mkpath
    path.write(contents)
  end

  # Bundler added install --lockfile after 2.6
  def bundler_has_install_option?(name)
    Bundler::CLI.commands.fetch("install").options.key?(name)
  end

  def lock_for(*gems)
    specs = gems.map { |name| "    #{name} (1.0.0)" }.join("\n")
    deps = gems.map { |name| "  #{name}" }.join("\n")

    <<~LOCK
      GEM
        remote: https://rubygems.org/
        specs:
      #{specs}

      PLATFORMS
        ruby

      DEPENDENCIES
      #{deps}
    LOCK
  end

  def plan_for(argv, gemfile_contents: "gem \"rake\"\n", lock: nil)
    write(root.join("Gemfile"), "source \"https://rubygems.org\"\ngem \"rake\"\n")
    write(gemfile, gemfile_contents)
    write(Pathname("#{gemfile}.lock"), lock) if lock

    invocation = BundleMatrix::Invocation.parse(argv)
    described_class.new(invocation, gemfile, root).plan
  end

  def locked_by(version)
    "#{lock_for("rake")}\nBUNDLED WITH\n   #{version}\n"
  end

  context "when the secondary is a gems.rb" do
    let(:gemfile) { root.join("engines", "web", "gems.rb") }

    it "reads its lockfile from gems.locked" do
      write(root.join("engines", "web", "gems.locked"), lock_for("rake"))

      plan = plan_for(%w[update rake --conservative])

      expect(plan.invocation.to_argv).to eq(%w[update rake --conservative])
    end
  end

  it "reports a gemfile it cannot evaluate as an error instead of raising", :aggregate_failures do
    plan = plan_for(%w[add rack], gemfile_contents: "raise \"boom\"\n")

    expect(plan.invocation).to be_nil
    expect(plan.error).to include("boom")
  end

  it "reports a command it does not plan as an error instead of returning nil", :aggregate_failures do
    invocation = BundleMatrix::Invocation.new(command: "exec", options: [], gems: [], unknown: [])
    plan = described_class.new(invocation, gemfile, root).plan

    expect(plan.error).to eq("unknown command exec")
    expect(plan).to be_failed
  end

  context "when the plan's outcome is checked" do
    it "is neither failed nor skipped when it runs a command", :aggregate_failures do
      plan = plan_for(%w[install])

      expect(plan).not_to be_failed
      expect(plan).not_to be_skipped
    end

    it "is skipped when there is nothing to run", :aggregate_failures do
      plan = plan_for(%w[update rack], lock: lock_for("rake"))

      expect(plan).to be_skipped
      expect(plan).not_to be_failed
    end

    it "is failed when planning raised, and not skipped", :aggregate_failures do
      plan = plan_for(%w[add rack], gemfile_contents: "raise \"boom\"\n")

      expect(plan).to be_failed
      expect(plan).not_to be_skipped
    end
  end

  context "when the plan runs a command" do
    it "records the Bundler the lockfile names, even when it is the running one", :aggregate_failures do
      expect(plan_for(%w[install], lock: locked_by("2.5.23")).locked_bundler).to eq(Gem::Version.new("2.5.23"))
      expect(plan_for(%w[install], lock: locked_by(Bundler::VERSION)).locked_bundler)
        .to eq(Gem::Version.new(Bundler::VERSION))
    end

    it "records no Bundler for a gemfile without a lockfile" do
      expect(plan_for(%w[install]).locked_bundler).to be_nil
    end

    it "records no Bundler for a gemfile that is skipped" do
      expect(plan_for(%w[update rack], lock: locked_by("2.5.23")).locked_bundler).to be_nil
    end
  end

  context "when the command is install" do
    it "removes --gemfile, which is set through BUNDLE_GEMFILE instead" do
      plan = plan_for(%w[install --gemfile Gemfile --jobs 4])

      expect(plan.invocation.to_argv).to eq(%w[install --jobs 4])
    end

    it "drops --lockfile given inline with =", :aggregate_failures do
      skip "Bundler #{Bundler::VERSION} has no install --lockfile" unless bundler_has_install_option?("lockfile")

      plan = plan_for(%w[install --lockfile=other.lock])

      expect(plan.invocation.to_argv).to eq(%w[install])
      expect(plan.notes).to eq(["--lockfile is not forwarded to other gemfiles"])
    end

    it "drops --standalone, which only makes sense for the main Gemfile", :aggregate_failures do
      plan = plan_for(%w[install --standalone --jobs 2])

      expect(plan.invocation.to_argv).to eq(%w[install --jobs 2])
      expect(plan.notes).to eq(["--standalone is not forwarded to other gemfiles"])
    end

    it "drops --lockfile and --standalone, which only make sense for the main Gemfile", :aggregate_failures do
      skip "Bundler #{Bundler::VERSION} has no install --lockfile" unless bundler_has_install_option?("lockfile")

      plan = plan_for(%w[install --lockfile other.lock --standalone --jobs 2])

      expect(plan.invocation.to_argv).to eq(%w[install --jobs 2])
      expect(plan.notes).to eq([
        "--lockfile is not forwarded to other gemfiles",
        "--standalone is not forwarded to other gemfiles"
      ])
    end
  end

  context "when the command is update" do
    it "runs a bare update in full, even without a lockfile" do
      expect(plan_for(%w[update]).invocation.to_argv).to eq(%w[update])
    end

    it "forwards --all and --conservative untouched" do
      plan = plan_for(%w[update --all --conservative])

      expect(plan.invocation.to_argv).to eq(%w[update --all --conservative])
    end

    it "forwards --patch and --conservative with named gems" do
      plan = plan_for(%w[update rake --patch --conservative], lock: lock_for("rake"))

      expect(plan.invocation.to_argv).to eq(%w[update rake --patch --conservative])
    end

    it "keeps only the named gems that appear in the secondary lockfile" do
      plan = plan_for(%w[update rake rack --conservative], lock: lock_for("rake"))

      expect(plan.invocation.to_argv).to eq(%w[update rake --conservative])
    end

    it "narrows the update for --no-all instead of running a full update" do
      plan = plan_for(%w[update --no-all rake --conservative], lock: lock_for("rake"))

      expect(plan.invocation.to_argv).to eq(%w[update rake --no-all --conservative])
    end

    it "skips the gemfile when none of the named gems are locked" do
      plan = plan_for(%w[update rack], lock: lock_for("rake"))

      expect(plan.invocation).to be_nil
    end

    it "runs install instead of a targeted update when there is no lockfile yet", :aggregate_failures do
      plan = plan_for(%w[update rake --jobs 3])

      expect(plan.invocation.to_argv).to eq(%w[install --jobs 3])
      expect(plan.notes).to eq(["no lockfile yet, running install to create it"])
    end

    it "removes --gemfile from the install it runs instead" do
      plan = plan_for(%w[update rake --gemfile Gemfile --jobs 3])

      expect(plan.invocation.to_argv).to eq(%w[install --jobs 3])
    end

    it "keeps only declared groups" do
      gemfile_contents = "group :dev do\n  gem \"rake\"\nend\n"
      plan = plan_for(%w[update --group dev test], gemfile_contents: gemfile_contents, lock: lock_for("rake"))

      expect(plan.invocation.to_argv).to eq(%w[update --group dev])
    end

    it "does not evaluate the gemfile when no group was given" do
      plan = plan_for(%w[update rake], gemfile_contents: "gem ENV.fetch(\"BUNDLE_MATRIX_SPEC_UNSET\")\n", lock: lock_for("rake"))

      expect(plan).not_to be_failed
      expect(plan.invocation.to_argv).to eq(%w[update rake])
    end

    it "removes --gemfile, which is set through BUNDLE_GEMFILE instead" do
      plan = plan_for(%w[update --gemfile Gemfile --all])

      expect(plan.invocation.to_argv).to eq(%w[update --all])
    end

    it "forwards --bundler, so every lockfile's Bundler is updated" do
      plan = plan_for(%w[update --bundler], lock: lock_for("rake"))

      expect(plan.invocation.to_argv).to eq(%w[update --bundler])
    end
  end

  context "when the command is add" do
    it "adds gems the secondary does not declare" do
      plan = plan_for(%w[add rack --group dev], lock: lock_for("rake"))

      expect(plan.invocation.to_argv).to eq(%w[add rack --group dev])
    end

    it "forwards --version" do
      plan = plan_for(["add", "rack", "--version", "~> 1.0"])

      expect(plan.invocation.to_argv).to eq(["add", "rack", "--version", "~> 1.0"])
    end

    it "runs install instead when the secondary declares the gem itself", :aggregate_failures do
      plan = plan_for(%w[add rake --version 13.0])

      expect(plan.invocation.to_argv).to eq(%w[install])
      expect(plan.notes).to include("rake is already declared, not added again")
    end

    it "runs install instead when every gem is already declared, e.g. via eval_gemfile" do
      plan = plan_for(%w[add rake --group dev --quiet], gemfile_contents: "eval_gemfile \"../Gemfile\"\n")

      expect(plan.invocation.to_argv).to eq(%w[install --quiet])
    end

    it "notes the main-only flags it drops from that install", :aggregate_failures do
      plan = plan_for(%w[add rake --path vendor/rake --quiet], gemfile_contents: "eval_gemfile \"../Gemfile\"\n")

      expect(plan.invocation.to_argv).to eq(%w[install --quiet])
      expect(plan.notes).to eq([
        "rake is already declared, not added again",
        "gems already declared, re-locking with install",
        "--path is not forwarded to other gemfiles"
      ])
    end

    it "keeps an absolute --path pointing at the same place from the secondary gemfile's directory" do
      plan = plan_for(%w[add rack --path /opt/rack], lock: lock_for("rake"))

      expect(File.expand_path(plan.invocation.values("path").first, gemfile.dirname)).to eq("/opt/rack")
    end

    it "rewrites a relative --path so it resolves from the secondary gemfile's directory" do
      plan = plan_for(%w[add local_gem --path vendor/local_gem])

      expect(plan.invocation.values("path")).to eq(["../vendor/local_gem"])
    end

    it "keeps the absolute --path when no relative path exists, e.g. across Windows drives" do
      allow_any_instance_of(Pathname).to receive(:relative_path_from).and_raise(ArgumentError) # rubocop:disable RSpec/AnyInstance
      plan = plan_for(%w[add local_gem --path vendor/local_gem])

      expect(plan.invocation.values("path")).to eq([root.join("vendor", "local_gem").to_s])
    end

    context "when the gemfile is in the project root" do
      let(:gemfile) { root.join("ci.gemfile") }

      it "forwards a relative --path unchanged" do
        plan = plan_for(%w[add local_gem --path vendor/local_gem])

        expect(plan.invocation.values("path")).to eq(["vendor/local_gem"])
      end
    end
  end
end
