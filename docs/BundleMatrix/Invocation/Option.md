# Class: BundleMatrix::Invocation::Option

- **Inherits:** `Data`
- **Defined in:** [`lib/bundle_matrix/invocation.rb`](../../../lib/bundle_matrix/invocation.rb)

negated is true for a `--no-name` switch, which unsets the option rather than setting it

## Attributes

### <a id="method-i-name"></a>`#name`

```ruby
attr_reader :name
```

### <a id="method-i-negated"></a>`#negated`

```ruby
attr_reader :negated
```

### <a id="method-i-tokens"></a>`#tokens`

```ruby
attr_reader :tokens
```

### <a id="method-i-values"></a>`#values`

```ruby
attr_reader :values
```

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(name:, tokens:, values:, negated: false)`](#method-i-initialize) |  |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(name:, tokens:, values:, negated: false)
```
