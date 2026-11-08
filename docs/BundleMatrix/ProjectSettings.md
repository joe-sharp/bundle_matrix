# Module: BundleMatrix::ProjectSettings

- **Defined in:** [`lib/bundle_matrix/project_settings.rb`](../../lib/bundle_matrix/project_settings.rb)

The project's settings that a child run would otherwise lose: its .bundle/config,
which a child doesn't read because it looks in its own gemfile's directory, and
the BUNDLE_* variables the user set, which Bundler.with_unbundled_env strips.
They are passed on as BUNDLE_* variables, so a gemfile's own .bundle/config still wins.
Settings#all and #locations are not a plugin API, so a Bundler release can change them.

## Constants

### <a id="constant-MAIN_ONLY"></a>`MAIN_ONLY`

```ruby
MAIN_ONLY = %w[gemfile lockfile app_config bin_path].freeze
```

Settings that point at the main Gemfile's own files; each child sets these itself

### <a id="constant-PATHS"></a>`PATHS`

```ruby
PATHS = %w[path bin cache_path].freeze
```

Settings holding a path relative to the project root, which a child would
otherwise resolve from its own directory

## Class methods

| Method | Summary |
| --- | --- |
| [`.env(root)`](#method-c-env) | Returns BUNDLE_* variables for a child run |

### <a id="method-c-env"></a>`.env`

```ruby
def self.env(root)
```

**Returns:**

- (`Hash{String => String}`) — BUNDLE_* variables for a child run
