# frozen_string_literal: true

RSpec.describe(BundleMatrix::SecondaryGemfile) do
  let(:root) { Pathname(Dir.mktmpdir("bundle_matrix_root")).realpath }
  let(:gemfile) { root.join("gemfiles", "old.gemfile") }

  after { FileUtils.remove_entry(root) }

  def write(path, contents)
    path.dirname.mkpath
    path.write(contents)
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

  describe "#lockfile" do
    it "is <gemfile>.lock for a Gemfile-style gemfile" do
      expect(described_class.new(gemfile).lockfile).to eq(root.join("gemfiles", "old.gemfile.lock"))
    end

    it "is gems.locked for a gems.rb" do
      expect(described_class.new(root.join("engines", "web", "gems.rb")).lockfile)
        .to eq(root.join("engines", "web", "gems.locked"))
    end
  end

  describe "#locked?" do
    it "is false until the lockfile exists", :aggregate_failures do
      secondary = described_class.new(gemfile)

      expect(secondary).not_to be_locked
      write(Pathname("#{gemfile}.lock"), lock_for("rake"))
      expect(secondary).to be_locked
    end
  end

  describe "#bundler_version" do
    it "reads the BUNDLED WITH line of the lockfile" do
      write(Pathname("#{gemfile}.lock"), "#{lock_for("rake")}\nBUNDLED WITH\n   2.5.23\n")

      expect(described_class.new(gemfile).bundler_version).to eq(Gem::Version.new("2.5.23"))
    end

    it "is nil without a lockfile" do
      expect(described_class.new(gemfile).bundler_version).to be_nil
    end
  end

  describe "#lock_names" do
    it "lists the gems the lockfile specifies" do
      write(Pathname("#{gemfile}.lock"), lock_for("rake", "rack"))

      expect(described_class.new(gemfile).lock_names).to contain_exactly("rake", "rack")
    end
  end

  describe "declarations" do
    it "lists the gems and groups this gemfile declares", :aggregate_failures do
      write(gemfile, "gem \"rake\"\ngroup :dev do\n  gem \"rack\"\nend\n")

      secondary = described_class.new(gemfile)

      expect(secondary.declared_names).to eq(%w[rake rack])
      expect(secondary.declared_groups).to eq(%w[default dev])
    end

    it "includes the gems pulled in by eval_gemfile" do
      write(root.join("Gemfile"), "gem \"rake\"\n")
      write(gemfile, "eval_gemfile \"../Gemfile\"\ngem \"rack\"\n")

      expect(described_class.new(gemfile).declared_names).to eq(%w[rake rack])
    end
  end
end
