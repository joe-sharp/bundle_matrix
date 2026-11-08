# Class: BundleMatrix::Planner

- **Defined in:** [`lib/bundle_matrix/planner.rb`](../../lib/bundle_matrix/planner.rb)

Decides what to run against one secondary gemfile, given the command the
user ran on the main Gemfile.

## Namespaces

- [`BundleMatrix::Planner::Plan`](Planner/Plan.md) — invocation is nil when the gemfile should be skipped; notes explain why; error is set when planning failed; locked_bundler is the Bundler named in this gemfile's lockfile, set on every plan that runs a command

## Constants

### <a id="constant-MAIN_ONLY_INSTALL_OPTIONS"></a>`MAIN_ONLY_INSTALL_OPTIONS`

```ruby
MAIN_ONLY_INSTALL_OPTIONS = %w[lockfile standalone path].freeze
```

Install flags that only make sense for the main Gemfile, or that Bundler no longer accepts

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(invocation, gemfile, root)`](#method-i-initialize) |  |
| [`#plan`](#method-i-plan) |  |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(invocation, gemfile, root)
```

### <a id="method-i-plan"></a>`#plan`

```ruby
def plan
```
