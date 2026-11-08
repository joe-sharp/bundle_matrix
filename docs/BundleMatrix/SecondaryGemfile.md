# Class: BundleMatrix::SecondaryGemfile

- **Defined in:** [`lib/bundle_matrix/secondary_gemfile.rb`](../../lib/bundle_matrix/secondary_gemfile.rb)

A secondary gemfile, and what its lockfile and declarations say about it.

## Attributes

### <a id="method-i-path"></a>`#path`

```ruby
attr_reader :path
```

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(path)`](#method-i-initialize) |  |
| [`#bundler_version`](#method-i-bundler_version) | The Bundler this gemfile's lockfile names in BUNDLED WITH, nil without a lockfile |
| [`#declared_groups`](#method-i-declared_groups) |  |
| [`#declared_names`](#method-i-declared_names) |  |
| [`#lock_names`](#method-i-lock_names) | Empty without a lockfile |
| [`#locked?`](#method-i-locked-3F) |  |
| [`#lockfile`](#method-i-lockfile) | Bundler locks a gems.rb in gems.locked, and every other gemfile in <gemfile>.lock |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(path)
```

### <a id="method-i-bundler_version"></a>`#bundler_version`

```ruby
def bundler_version
```

The Bundler this gemfile's lockfile names in BUNDLED WITH, nil without a lockfile

### <a id="method-i-declared_groups"></a>`#declared_groups`

```ruby
def declared_groups
```

### <a id="method-i-declared_names"></a>`#declared_names`

```ruby
def declared_names
```

### <a id="method-i-lock_names"></a>`#lock_names`

```ruby
def lock_names
```

Empty without a lockfile

### <a id="method-i-locked-3F"></a>`#locked?`

```ruby
def locked?
```

### <a id="method-i-lockfile"></a>`#lockfile`

```ruby
def lockfile
```

Bundler locks a gems.rb in gems.locked, and every other gemfile in <gemfile>.lock
