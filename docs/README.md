# BundleMatrix

A Bundler plugin that repeats `bundle install`, `bundle update` and `bundle add` against every other gemfile in your project, so each lockfile stays in step with the main `Gemfile`.

Projects that test against several dependency sets keep extra gemfiles (`ci.gemfile`, `gemfiles/rails7.gemfile`, engine Gemfiles, and so on). Without help, every one of them needs its own `BUNDLE_GEMFILE=… bundle install`. With bundle_matrix, running the command on the main `Gemfile` does that for you.

![BundleMatrix](https://raw.githubusercontent.com/joe-sharp/bundle_matrix/main/BundleMatrix.webp)

## Installation

Install the plugin once for your user:

```bash
bundle plugin install bundle_matrix
```

Or declare it in the project's `Gemfile`:

```ruby
plugin "bundle_matrix"
```

## Usage

Run the command on the main `Gemfile` as usual:

```bash
bundle install
bundle update rails --conservative
bundle update --all
bundle add rack --group development
```

After the main run succeeds, each discovered gemfile is run with the same command and flags. Output is headed by the gemfile it applies to:

```
== bundle_matrix: gemfiles/rails7.gemfile -> bundle update rails --conservative
== bundle_matrix: engines/admin/Gemfile -> bundle install
```

Only `install`, `update` and `add` are fanned out. `bundle check`, `bundle exec` and similar commands are not, because Bundler does not run plugin hooks for them.

Bundler's short forms work too: `bundle i`, `bundle ins`, `bundle a`, `bundle u`, and any other unambiguous prefix of a command name.

A plain `bundle`, or `bundle` with only flags such as `bundle --jobs=4`, runs as `install` and fans out as `install`, but only while `default_cli_command` is unset or `install`. With it set to `cli_help`, those commands print help and nothing fans out. Bundler's documentation already names `cli_help` as the default, while its code still runs `install` and prints a notice that this will change. To keep fanning out whatever Bundler does, set the setting explicitly, or run `bundle install`:

```bash
bundle config set default_cli_command install
```

## Which gemfiles are found

The main gemfile is `Gemfile` in the project root, or the file named by `matrix.default_gemfile`. It is never treated as a secondary gemfile. Secondary gemfiles are found in:

- `*.gemfile` in the project root, e.g. `ci.gemfile` with `ci.gemfile.lock`
- `*.gemfile` in `gemfiles/`
- any directories listed in `matrix.paths`, each contributing its `gems.rb`, or its `Gemfile` when it has no `gems.rb`, the order Bundler uses

## Configuration

Settings use `bundle config` or `BUNDLE_MATRIX__*` environment variables:

| Setting | Default | Meaning |
| --- | --- | --- |
| `matrix.default_gemfile` | `Gemfile` | File name of the main gemfile in the project root. Fan-out starts only when the command runs on this file, e.g. `gems.rb` |
| `matrix.paths` | none | Extra directories or globs to search for a `gems.rb` or `Gemfile`, separated by commas, e.g. `engines/*,apps/admin` |
| `matrix.disabled` | `false` | Turn fan-out off |
| `matrix.fail_fast` | `false` | Stop at the first failing gemfile |
| `matrix.bundler_warnings` | `true` | Warn when a gemfile runs a different Bundler from the main Gemfile. Set it to `false` for projects that pin different Bundlers on purpose |

```bash
bundle config set matrix.paths "engines/*,apps/admin"
```

For a project whose main file is `gems.rb`, set the main gemfile name once, and run the command on `gems.rb`:

```bash
bundle config set matrix.default_gemfile gems.rb
bundle install
```

To skip the matrix for a single run, set `BUNDLE_MATRIX__DISABLED` on that command:

```bash
BUNDLE_MATRIX__DISABLED=1 bundle install
```

`bundle config set matrix.disabled true` is the persistent version, and stays in effect until you change it back.

## How each command is applied

Flags are forwarded as typed, and Bundler's own option table decides what each flag means. The exceptions below are where a flag can't be applied to another gemfile as-is.

- **`install`**: `--lockfile` and `--standalone` only apply to the main Gemfile, so they are not forwarded.
- **`update <gems>`**: only the named gems that appear in that gemfile's lockfile are updated. A gemfile with none of them is skipped. `--group` is limited to groups it declares. If it has no lockfile yet, `install` is run to create one.
- **`update --all`**, `--conservative`, `--patch`, `--minor`, `--major`, `--pre`, `--strict` and the rest: forwarded unchanged.
- **`add <gems>`**: gems the gemfile already declares, including through `eval_gemfile`, are not added again. If every gem is already declared, `install` is run to re-lock the gemfile. A relative `--path` is rewritten so it resolves from that gemfile's directory.
- `--gemfile` is never forwarded. The target is set through `BUNDLE_GEMFILE` instead.

## Settings and Bundler versions

Each gemfile is run the way `bundle` would run it on its own, with the project's settings:

- The project's `.bundle/config` and the `BUNDLE_*` environment variables you set are passed on, so `frozen`, `without`, `jobs` and the rest apply to every gemfile. A relative `path`, `bin` or `cache_path` still resolves from the project root, so every gemfile shares the same `vendor/bundle`. A `.bundle/config` next to a secondary gemfile takes priority for that gemfile.
- `gemfile` and `lockfile` are not passed on, because they name the main Gemfile's own files.
- Each gemfile runs with the Bundler version in its own `BUNDLED WITH` line, and `install` installs that version first if it is missing. A `gem "bundler"` line in a gemfile that has no lockfile yet is not installed for you, so install that version yourself first. Bundler's `version` setting controls this: `bundle config set version system` keeps every gemfile on the running version, and `bundle config set version 4.0.23` pins one. `BUNDLER_VERSION` is not passed on, because it would hold every gemfile to one version.
- When a gemfile runs with a different Bundler from the main Gemfile, a one-line warning names both versions, and the run ends by suggesting either `bundle update --bundler`, which updates Bundler in every lockfile, or `bundle config set matrix.bundler_warnings false`, which turns these warnings off when each gemfile should keep its own Bundler.

## How it uses Bundler

bundle_matrix needs Bundler 2.6.9 or newer, below 4.2 and its prereleases, and is tested against 2.6.9, 2.7.2, 4.0.24 and 4.1.0.beta3. The upper bound moves up once a new Bundler minor has been tested. Under any other Bundler the plugin still runs, but prints a one-line warning that it is untested there, with a link to the issue tracker.

Fan-out starts from Bundler's documented plugin hook, `after-install-all`, and each gemfile runs in its own `bundle` process. Everything else uses Bundler classes that work today but are not a plugin API, so a new Bundler release could change them:

- Thor's command and option tables (`Bundler::CLI`), which decide what each flag means and which command was run (`ArgvParser`, `Invocation`). Command names such as `ins` are resolved by calling Thor's protected `normalize_command_name` with `send`
- `Bundler::Dsl` and `Bundler::LockfileParser`, which read each secondary gemfile and lockfile (`Planner`). `Bundler.definition` and `Bundler.locked_gems` only describe the main Gemfile, so they can't be used for the others.
- The settings' storage levels, through `Bundler.settings` (`ProjectSettings`)

## Limitations

- `bundle check` is not supported. Bundler only calls plugin hooks around installation.
- `bundle add --skip-install` never runs the hook, because no installation happens.
- Flags that Bundler does not know about are forwarded as-is, and any value after them is treated as a gem name.

## Development

Run `bin/setup`, then `rake`. The default task runs the unit specs, the end-to-end specs, RuboCop, `rake rbs`, which runs `rbs validate` on the signatures in `sig/` with the Bundler stubs in `sig_stubs/`, and `rake steep`, which type checks `lib/` against those signatures. Run `rake e2e` on its own for the end-to-end specs, which run real `bundle` commands and take longer. Run `COVERAGE=true bundle exec rake spec` to also write a coverage report to `coverage/index.html`. That run fails below 90% line coverage or 80% branch coverage, and CI runs it this way.

Run `bundle exec guard` to re-run the unit specs and RuboCop on every change. It also regenerates the docs when the files they are built from change.

`docs/` is generated by Boondoc, so edit `README.md` and the code comments rather than `docs/`. To regenerate it by hand, run `bundle exec boondoc`

To try a change against a real project, install from a local checkout with `bundle plugin install bundle_matrix --path /path/to/bundle_matrix` (the directory must contain `plugins.rb`).

## Contributing

Bug reports and pull requests are welcome. Send issues and pull requests to https://github.com/joe-sharp/bundle_matrix.

Run `bundle exec rake` before you open a pull request. The Development section above explains what it runs.

A bug report should include:

- the Bundler version, from `bundle -v`
- the command you ran, e.g. `bundle update rails --conservative`
- your gemfile layout: which gemfiles exist, where they are, and any `matrix.*` settings

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## API reference

- [`BundleMatrix`](BundleMatrix.md) — A Bundler plugin that repeats `install`, `update` and `add` against every secondary gemfile in a project.
  - [`BundleMatrix::ArgvParser`](BundleMatrix/ArgvParser.md) — Finds the command in argv the way Bundler does, then splits the tokens after it into options, gems and unknown switches, using the switch table Bundler itself uses for that command.
    - [`BundleMatrix::ArgvParser::Switch`](BundleMatrix/ArgvParser/Switch.md) — One switch Bundler accepts for a command; negated is true for its `--no-name` form
  - [`BundleMatrix::Config`](BundleMatrix/Config.md) — Reads the matrix.* settings, from `bundle config` or BUNDLE_MATRIX__* env vars.
  - [`BundleMatrix::Discovery`](BundleMatrix/Discovery.md) — Finds the secondary gemfiles that follow the main Gemfile.
  - [`BundleMatrix::Error`](BundleMatrix/Error.md) — Raised after the matrix run, when one or more secondary gemfiles failed
  - [`BundleMatrix::Hook`](BundleMatrix/Hook.md) — Called by Bundler after `install`, `update` or `add` has finished.
  - [`BundleMatrix::Invocation`](BundleMatrix/Invocation.md) — A parsed `bundle install\|update\|add` command line.
    - [`BundleMatrix::Invocation::Option`](BundleMatrix/Invocation/Option.md) — negated is true for a `--no-name` switch, which unsets the option rather than setting it
  - [`BundleMatrix::Planner`](BundleMatrix/Planner.md) — Decides what to run against one secondary gemfile, given the command the user ran on the main Gemfile.
    - [`BundleMatrix::Planner::Plan`](BundleMatrix/Planner/Plan.md) — invocation is nil when the gemfile should be skipped; notes explain why; error is set when planning failed; locked_bundler is the Bundler named in this gemfile's lockfile, set on every plan that runs a command
  - [`BundleMatrix::ProjectSettings`](BundleMatrix/ProjectSettings.md) — The project's settings that a child run would otherwise lose: its .bundle/config, which a child doesn't read because it looks in its own gemfile's directory, and the BUNDLE_* variables the user set, which Bundler.with_unbundled_env strips.
  - [`BundleMatrix::Runner`](BundleMatrix/Runner.md) — Runs each planned command in a separate `bundle` process.
  - [`BundleMatrix::SecondaryGemfile`](BundleMatrix/SecondaryGemfile.md) — A secondary gemfile, and what its lockfile and declarations say about it.
