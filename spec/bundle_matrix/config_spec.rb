# frozen_string_literal: true

RSpec.describe(BundleMatrix::Config) do
  let(:root) { Pathname(Dir.mktmpdir("bundle_matrix_root")).realpath }
  let(:config) { described_class.new }

  after { FileUtils.remove_entry(root) }

  def settings(local_config: {}, env: {})
    root.join(".bundle").mkpath
    root.join(".bundle", "config").write(local_config.map { |key, value| "#{key}: \"#{value}\"\n" }.join)
    stub_const("ENV", isolated_env(env))
    allow(Bundler).to receive(:settings).and_return(Bundler::Settings.new(root.join(".bundle")))
  end

  # Keeps the developer's own BUNDLE_MATRIX__* vars and global Bundler config out of the spec.
  # Bundler checks BUNDLE_CONFIG before BUNDLE_USER_CONFIG, so BUNDLE_CONFIG has to go too.
  def isolated_env(env)
    ENV.to_h
      .reject { |key, _| key == "BUNDLE_CONFIG" || key.start_with?("BUNDLE_MATRIX__") }
      .merge("BUNDLE_USER_CONFIG" => root.join("global_config").to_s, **env)
  end

  it "splits matrix.paths on commas only, so a colon stays in the path" do
    settings(local_config: { "BUNDLE_MATRIX__PATHS" => "engines/*, apps/admin,C:/engines" })

    expect(config.paths).to eq(["engines/*", "apps/admin", "C:/engines"])
  end

  it "has no paths when matrix.paths is not set" do
    settings

    expect(config.paths).to eq([])
  end

  it "drops empty entries and surrounding whitespace from matrix.paths" do
    settings(local_config: { "BUNDLE_MATRIX__PATHS" => " a ,, b ," })

    expect(config.paths).to eq(%w[a b])
  end

  it "uses Gemfile as the default gemfile when matrix.default_gemfile is not set" do
    settings

    expect(config.default_gemfile).to eq("Gemfile")
  end

  it "reads the default gemfile from bundle config" do
    settings(local_config: { "BUNDLE_MATRIX__DEFAULT_GEMFILE" => "gems.rb" })

    expect(config.default_gemfile).to eq("gems.rb")
  end

  it "reads the default gemfile from BUNDLE_MATRIX__DEFAULT_GEMFILE" do
    settings(env: { "BUNDLE_MATRIX__DEFAULT_GEMFILE" => "gems.rb" })

    expect(config.default_gemfile).to eq("gems.rb")
  end

  it "is neither disabled nor fail fast by default", :aggregate_failures do
    settings

    expect(config).not_to be_disabled
    expect(config).not_to be_fail_fast
  end

  it "prefers bundle config over BUNDLE_MATRIX__* env vars" do
    settings(local_config: { "BUNDLE_MATRIX__DISABLED" => "true" }, env: { "BUNDLE_MATRIX__DISABLED" => "no" })

    expect(config).to be_disabled
  end

  it "is disabled with bundle config" do
    settings(local_config: { "BUNDLE_MATRIX__DISABLED" => "true" })

    expect(config).to be_disabled
  end

  it "is disabled with BUNDLE_MATRIX__DISABLED" do
    settings(env: { "BUNDLE_MATRIX__DISABLED" => "1" })

    expect(config).to be_disabled
  end

  it "treats true and yes as on, regardless of case", :aggregate_failures do
    settings(local_config: { "BUNDLE_MATRIX__DISABLED" => "TRUE", "BUNDLE_MATRIX__FAIL_FAST" => "YES" })

    expect(config).to be_disabled
    expect(config).to be_fail_fast
  end

  it "treats false as off" do
    settings(local_config: { "BUNDLE_MATRIX__DISABLED" => "false" })

    expect(config).not_to be_disabled
  end

  it "treats an empty value as off" do
    settings(local_config: { "BUNDLE_MATRIX__DISABLED" => "" })

    expect(config).not_to be_disabled
  end

  it "warns about other Bundler versions by default" do
    settings

    expect(config).to be_bundler_warnings
  end

  it "turns off Bundler version warnings when matrix.bundler_warnings is false, 0 or no", :aggregate_failures do
    %w[false 0 NO].each do |value|
      settings(local_config: { "BUNDLE_MATRIX__BUNDLER_WARNINGS" => value })
      expect(config).not_to be_bundler_warnings
    end
  end

  it "turns off Bundler version warnings with BUNDLE_MATRIX__BUNDLER_WARNINGS" do
    settings(env: { "BUNDLE_MATRIX__BUNDLER_WARNINGS" => "false" })

    expect(config).not_to be_bundler_warnings
  end

  it "treats anything other than true, 1 or yes as off", :aggregate_failures do
    settings(local_config: { "BUNDLE_MATRIX__DISABLED" => "no", "BUNDLE_MATRIX__FAIL_FAST" => "off" })

    expect(config).not_to be_disabled
    expect(config).not_to be_fail_fast
  end
end
