# Class: BundleMatrix::ArgvParser::Switch

- **Inherits:** `Data`
- **Defined in:** [`lib/bundle_matrix/argv_parser.rb`](../../../lib/bundle_matrix/argv_parser.rb)

One switch Bundler accepts for a command; negated is true for its `--no-name` form

## Attributes

### <a id="method-i-name"></a>`#name`

```ruby
attr_reader :name
```

### <a id="method-i-negated"></a>`#negated`

```ruby
attr_reader :negated
```

### <a id="method-i-option"></a>`#option`

```ruby
attr_reader :option
```

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(name:, option:, negated: false)`](#method-i-initialize) |  |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(name:, option:, negated: false)
```
