## [Unreleased]

## [0.1.0] - 2026-11-08

Initial release. bundle_matrix is a Bundler plugin that repeats `bundle install`, `bundle update` and `bundle add` against every secondary gemfile in your project, so each lockfile stays in step with the main gemfile.

- Finds secondary gemfiles (`*.gemfile` in the project root and `gemfiles/`), plus `gems.rb` or `Gemfile` in any directories listed in `matrix.paths`
- Forwards the same flags to each gemfile, handling gems, groups, `--path` and `--lockfile` per gemfile
- Runs each secondary gemfile with its own lockfile's Bundler version
- Shares the project's `.bundle/config` and `BUNDLE_*` environment variables with every gemfile
- Recognizes command aliases and prefixes (`i`, `a`, `u`) and plain `bundle`, as Bundler does
- Reports a gemfile that fails as an error and keeps going with the rest
