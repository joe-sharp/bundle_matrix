# frozen_string_literal: true

RSpec.describe(BundleMatrix) do
  # The Bundler versions the Appraisals generate gemfiles for, from the file names
  let(:tested) do
    Dir.glob(File.join(__dir__, "..", "gemfiles", "bundler_*.gemfile")).map do |path|
      Gem::Version.new(File.basename(path, ".gemfile").delete_prefix("bundler_"))
    end
  end

  it "accepts every Bundler the Appraisals test", :aggregate_failures do
    expect(tested).not_to be_empty
    expect(tested).to all(satisfy { |version| BundleMatrix::TESTED_BUNDLER.satisfied_by?(version) })
  end

  it "excludes the minor after the highest tested one", :aggregate_failures do
    highest = tested.max
    next_minor = Gem::Version.new("#{highest.segments[0]}.#{highest.segments[1] + 1}.a")

    expect(BundleMatrix::TESTED_BUNDLER.satisfied_by?(highest)).to be(true)
    expect(BundleMatrix::TESTED_BUNDLER.satisfied_by?(next_minor)).to be(false)
  end

  it "lets the gemspec install under a Bundler newer than the tested range", :aggregate_failures do
    gemspec = Gem::Specification.load(File.join(__dir__, "..", "bundle_matrix.gemspec"))
    requirement = gemspec.dependencies.find { |dependency| dependency.name == "bundler" }.requirement

    expect(requirement.satisfied_by?(Gem::Version.new("4.2.0"))).to be(true)
    expect(requirement.satisfied_by?(Gem::Version.new(BundleMatrix::MIN_BUNDLER))).to be(true)
    expect(requirement.satisfied_by?(Gem::Version.new("2.6.8"))).to be(false)
  end
end
