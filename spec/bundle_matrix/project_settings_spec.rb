# frozen_string_literal: true

RSpec.describe(BundleMatrix::ProjectSettings) do
  let(:root) { Pathname(Dir.mktmpdir("bundle_matrix_root")).realpath }
  let(:user_env) { {} }

  after { FileUtils.remove_entry(root) }

  # Keeps the developer's own BUNDLE_* variables and global Bundler config out of the spec
  # rubocop:disable-next Metrics/AbcSize
  def env_with(local_config)
    root.join(".bundle").mkpath
    root.join(".bundle", "config").write(local_config.map { |key, value| "#{key}: \"#{value}\"\n" }.join)
    stub_const("ENV", isolated_env.merge(user_env))
    allow(Bundler).to receive_messages(settings: Bundler::Settings.new(root.join(".bundle")), original_env: user_env)
    described_class.env(root)
  end

  def isolated_env
    ENV.to_h
      .reject { |key, _| key == "BUNDLE_CONFIG" || key.start_with?("BUNDLE_") }
      .merge("BUNDLE_USER_CONFIG" => root.join("global_config").to_s)
  end

  it "passes on the project's .bundle/config" do
    env = env_with("BUNDLE_FROZEN" => "true", "BUNDLE_WITHOUT" => "development:test")

    expect(env).to include("BUNDLE_FROZEN" => "true", "BUNDLE_WITHOUT" => "development:test")
  end

  # Bundler.settings lists the keys from ENV, and the values the user set come from Bundler.original_env
  it "passes on BUNDLE_* variables the user set in the original environment" do
    user_env["BUNDLE_JOBS"] = "4"

    expect(env_with({})).to include("BUNDLE_JOBS" => "4")
  end

  it "prefers .bundle/config over the user's BUNDLE_* variables" do
    user_env["BUNDLE_FROZEN"] = "false"

    expect(env_with("BUNDLE_FROZEN" => "true")).to include("BUNDLE_FROZEN" => "true")
  end

  it "expands relative paths from the project root" do
    env = env_with("BUNDLE_PATH" => "vendor/bundle", "BUNDLE_BIN" => "/usr/local/bin")

    expect(env).to include("BUNDLE_PATH" => root.join("vendor/bundle").to_s, "BUNDLE_BIN" => "/usr/local/bin")
  end

  it "leaves out settings that point at the main Gemfile's own files" do
    env = env_with("BUNDLE_GEMFILE" => "Gemfile", "BUNDLE_LOCKFILE" => "Gemfile.next.lock", "BUNDLE_JOBS" => "4")

    expect(env.keys).to eq(["BUNDLE_JOBS"])
  end
end
