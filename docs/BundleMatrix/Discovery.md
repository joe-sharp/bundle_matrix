# Class: BundleMatrix::Discovery

- **Defined in:** [`lib/bundle_matrix/discovery.rb`](../../lib/bundle_matrix/discovery.rb)

Finds the secondary gemfiles that follow the main Gemfile.

## Constants

### <a id="constant-DIRECTORY_GEMFILES"></a>`DIRECTORY_GEMFILES`

```ruby
DIRECTORY_GEMFILES = %w[gems.rb Gemfile].freeze
```

The gemfile a matrix.paths directory contributes, in Bundler's order

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(root, paths, default_gemfile:)`](#method-i-initialize) | default_gemfile is the main gemfile's file name in root; it is never returned, whatever its name |
| [`#gemfiles`](#method-i-gemfiles) | Returns sorted, unique, excluding the main gemfile |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(root, paths, default_gemfile:)
```

default_gemfile is the main gemfile's file name in root; it is never returned, whatever its name

### <a id="method-i-gemfiles"></a>`#gemfiles`

```ruby
def gemfiles
```

**Returns:**

- (`Array<Pathname>`) — sorted, unique, excluding the main gemfile
