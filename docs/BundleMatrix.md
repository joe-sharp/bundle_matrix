# Module: BundleMatrix

- **Defined in:** [`lib/bundle_matrix.rb`](../lib/bundle_matrix.rb), [`lib/bundle_matrix/argv_parser.rb`](../lib/bundle_matrix/argv_parser.rb), [`lib/bundle_matrix/config.rb`](../lib/bundle_matrix/config.rb), [`lib/bundle_matrix/discovery.rb`](../lib/bundle_matrix/discovery.rb), [`lib/bundle_matrix/hook.rb`](../lib/bundle_matrix/hook.rb), [`lib/bundle_matrix/invocation.rb`](../lib/bundle_matrix/invocation.rb), [`lib/bundle_matrix/planner.rb`](../lib/bundle_matrix/planner.rb), [`lib/bundle_matrix/project_settings.rb`](../lib/bundle_matrix/project_settings.rb), [`lib/bundle_matrix/runner.rb`](../lib/bundle_matrix/runner.rb), [`lib/bundle_matrix/secondary_gemfile.rb`](../lib/bundle_matrix/secondary_gemfile.rb), [`lib/bundle_matrix/version.rb`](../lib/bundle_matrix/version.rb)

A Bundler plugin that repeats `install`, `update` and `add` against every secondary gemfile in a project.

## Namespaces

- [`BundleMatrix::ArgvParser`](BundleMatrix/ArgvParser.md) — Finds the command in argv the way Bundler does, then splits the tokens after it into options, gems and unknown switches, using the switch table Bundler itself uses for that command.
- [`BundleMatrix::Config`](BundleMatrix/Config.md) — Reads the matrix.* settings, from `bundle config` or BUNDLE_MATRIX__* env vars.
- [`BundleMatrix::Discovery`](BundleMatrix/Discovery.md) — Finds the secondary gemfiles that follow the main Gemfile.
- [`BundleMatrix::Error`](BundleMatrix/Error.md) — Raised after the matrix run, when one or more secondary gemfiles failed
- [`BundleMatrix::Hook`](BundleMatrix/Hook.md) — Called by Bundler after `install`, `update` or `add` has finished.
- [`BundleMatrix::Invocation`](BundleMatrix/Invocation.md) — A parsed `bundle install\|update\|add` command line.
- [`BundleMatrix::Planner`](BundleMatrix/Planner.md) — Decides what to run against one secondary gemfile, given the command the user ran on the main Gemfile.
- [`BundleMatrix::ProjectSettings`](BundleMatrix/ProjectSettings.md) — The project's settings that a child run would otherwise lose: its .bundle/config, which a child doesn't read because it looks in its own gemfile's directory, and the BUNDLE_* variables the user set, which Bundler.with_unbundled_env strips.
- [`BundleMatrix::Runner`](BundleMatrix/Runner.md) — Runs each planned command in a separate `bundle` process.
- [`BundleMatrix::SecondaryGemfile`](BundleMatrix/SecondaryGemfile.md) — A secondary gemfile, and what its lockfile and declarations say about it.

## Constants

### <a id="constant-MIN_BUNDLER"></a>`MIN_BUNDLER`

```ruby
MIN_BUNDLER = "2.6.9"
```

The oldest Bundler the plugin runs under. The gemspec requires it, and nothing newer is refused.
It is where Bundler::SharedHelpers.relative_path_to, which Planner uses, first appeared.

### <a id="constant-TESTED_BUNDLER"></a>`TESTED_BUNDLER`

```ruby
TESTED_BUNDLER = Gem::Requirement.new(">= #{MIN_BUNDLER}", "< 4.2.a")
```

The Bundler versions the Appraisals test. The hook warns outside this range, not the gemspec.
The `.a` keeps 4.2 prereleases out too; raise it once a new Bundler minor has been tested.

### <a id="constant-VERSION"></a>`VERSION`

```ruby
VERSION = "0.1.0"
```
