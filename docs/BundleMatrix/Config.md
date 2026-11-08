# Class: BundleMatrix::Config

- **Defined in:** [`lib/bundle_matrix/config.rb`](../../lib/bundle_matrix/config.rb)

Reads the matrix.* settings, from `bundle config` or BUNDLE_MATRIX__* env vars.

## Constants

### <a id="constant-DEFAULT_GEMFILE"></a>`DEFAULT_GEMFILE`

```ruby
DEFAULT_GEMFILE = "Gemfile"
```

### <a id="constant-FALSE_VALUES"></a>`FALSE_VALUES`

```ruby
FALSE_VALUES = %w[false 0 no].freeze
```

### <a id="constant-TRUE_VALUES"></a>`TRUE_VALUES`

```ruby
TRUE_VALUES = %w[true 1 yes].freeze
```

## Instance methods

| Method | Summary |
| --- | --- |
| [`#bundler_warnings?`](#method-i-bundler_warnings-3F) | Warn when a gemfile runs a different Bundler from the main one; on unless set to false, 0 or no |
| [`#default_gemfile`](#method-i-default_gemfile) | The file name of the main gemfile in the project root, e.g. |
| [`#disabled?`](#method-i-disabled-3F) |  |
| [`#fail_fast?`](#method-i-fail_fast-3F) |  |
| [`#paths`](#method-i-paths) | Extra directories (or globs) to search for a Gemfile, e.g. |

### <a id="method-i-bundler_warnings-3F"></a>`#bundler_warnings?`

```ruby
def bundler_warnings?
```

Warn when a gemfile runs a different Bundler from the main one; on unless set to false, 0 or no

### <a id="method-i-default_gemfile"></a>`#default_gemfile`

```ruby
def default_gemfile
```

The file name of the main gemfile in the project root, e.g. "gems.rb". Fan-out starts from it.

### <a id="method-i-disabled-3F"></a>`#disabled?`

```ruby
def disabled?
```

### <a id="method-i-fail_fast-3F"></a>`#fail_fast?`

```ruby
def fail_fast?
```

### <a id="method-i-paths"></a>`#paths`

```ruby
def paths
```

Extra directories (or globs) to search for a Gemfile, e.g. "engines/*,apps/admin".
