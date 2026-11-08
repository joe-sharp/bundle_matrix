# frozen_string_literal: true

RSpec.describe(BundleMatrix::Discovery) do
  let(:root) { Pathname(Dir.mktmpdir("bundle_matrix_root")).realpath }

  after { FileUtils.remove_entry(root) }

  def touch(*parts)
    path = root.join(*parts)
    path.dirname.mkpath
    path.write("")
    path
  end

  def relative(gemfiles)
    gemfiles.map { |path| path.relative_path_from(root).to_s }
  end

  before do
    touch("Gemfile")
    touch("Gemfile.lock")
    touch("ci.gemfile")
    touch("ci.gemfile.lock")
    touch("gemfiles", "rails7.gemfile")
    touch("gemfiles", "rails7.gemfile.lock")
    touch("engines", "admin", "Gemfile")
    touch("engines", "api", "Gemfile")
    touch("engines", "api.txt")
  end

  it "finds *.gemfile in the root and in gemfiles/, but not lockfiles or the main Gemfile" do
    found = described_class.new(root, [], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile gemfiles/rails7.gemfile])
  end

  it "finds gemfiles when the project path contains glob characters" do
    touch("app[v2]", "ci.gemfile")
    touch("app[v2]", "gemfiles", "rails.gemfile")

    found = described_class.new(root.join("app[v2]"), [], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to eq(%w[app[v2]/ci.gemfile app[v2]/gemfiles/rails.gemfile])
  end

  it "lists a gemfile once when matrix.paths entries overlap" do
    found = described_class.new(root, ["engines/*", "engines/admin"], default_gemfile: "Gemfile").gemfiles

    expect(relative(found).count("engines/admin/Gemfile")).to eq(1)
  end

  it "finds Gemfiles in configured directories, with globs" do
    found = described_class.new(root, ["engines/*"], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile engines/admin/Gemfile engines/api/Gemfile gemfiles/rails7.gemfile])
  end

  it "accepts a gemfile path directly" do
    touch("apps", "web.gemfile")

    found = described_class.new(root, ["apps/web.gemfile"], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to include("apps/web.gemfile")
  end

  it "never returns the main gemfile, even when its name ends in .gemfile" do
    touch("foo.gemfile")
    touch("foo.gemfile.lock")

    found = described_class.new(root, [], default_gemfile: "foo.gemfile").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile gemfiles/rails7.gemfile])
  end

  it "keeps Gemfile as a secondary when the main gemfile is named differently" do
    touch("gems.rb")

    found = described_class.new(root, [], default_gemfile: "gems.rb").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile gemfiles/rails7.gemfile])
  end

  it "uses gems.rb in a configured directory that has no Gemfile" do
    touch("engines", "web", "gems.rb")

    found = described_class.new(root, ["engines/web"], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile engines/web/gems.rb gemfiles/rails7.gemfile])
  end

  it "uses a gems.rb named directly in matrix.paths" do
    touch("engines", "web", "gems.rb")

    found = described_class.new(root, ["engines/web/gems.rb"], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile engines/web/gems.rb gemfiles/rails7.gemfile])
  end

  it "prefers gems.rb over Gemfile in a configured directory, as Bundler does" do
    touch("engines", "api", "gems.rb")

    found = described_class.new(root, ["engines/api"], default_gemfile: "Gemfile").gemfiles

    expect(relative(found)).to eq(%w[ci.gemfile engines/api/gems.rb gemfiles/rails7.gemfile])
  end

  it "skips the main gems.rb when matrix.paths points at the project root" do
    touch("gems.rb")
    root.join("Gemfile").delete

    found = described_class.new(root, ["."], default_gemfile: "gems.rb").gemfiles

    expect(relative(found)).not_to include("gems.rb")
  end

  it "warns when a configured path matches nothing" do
    allow(Bundler.ui).to receive(:warn)

    described_class.new(root, ["nowhere/*"], default_gemfile: "Gemfile").gemfiles

    expect(Bundler.ui).to have_received(:warn).with(%r{nowhere/\*})
  end
end
