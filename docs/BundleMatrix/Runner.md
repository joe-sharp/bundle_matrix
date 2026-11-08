# Class: BundleMatrix::Runner

- **Defined in:** [`lib/bundle_matrix/runner.rb`](../../lib/bundle_matrix/runner.rb)

Runs each planned command in a separate `bundle` process. Bundler keeps
global state, so the secondary gemfiles can't be run in this process.

## Constants

### <a id="constant-BUNDLE"></a>`BUNDLE`

```ruby
BUNDLE = File.expand_path("bundle", __dir__)
```

Launched like a plain `bundle`, so RubyGems and Bundler pick each gemfile's Bundler version.
__dir__ is only nil inside eval, which Steep can't rule out.

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(root, fail_fast: false, bundler_warnings: true)`](#method-i-initialize) | bundler_warnings is false when the matrix.bundler_warnings setting turns off the Bundler version warnings |
| [`#run(plans)`](#method-i-run) |  |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(root, fail_fast: false, bundler_warnings: true)
```

bundler_warnings is false when the matrix.bundler_warnings setting turns off the Bundler version warnings

### <a id="method-i-run"></a>`#run`

```ruby
def run(plans)
```

**Parameters:**

- `plans` (`Hash{Pathname => `[`Planner::Plan`](Planner/Plan.md)`}`)
