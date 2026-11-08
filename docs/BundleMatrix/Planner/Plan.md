# Class: BundleMatrix::Planner::Plan

- **Inherits:** `Data`
- **Defined in:** [`lib/bundle_matrix/planner.rb`](../../../lib/bundle_matrix/planner.rb)

invocation is nil when the gemfile should be skipped; notes explain why; error is set when planning failed;
locked_bundler is the Bundler named in this gemfile's lockfile, set on every plan that runs a command

## Attributes

### <a id="method-i-error"></a>`#error`

```ruby
attr_reader :error
```

### <a id="method-i-invocation"></a>`#invocation`

```ruby
attr_reader :invocation
```

### <a id="method-i-locked_bundler"></a>`#locked_bundler`

```ruby
attr_reader :locked_bundler
```

### <a id="method-i-notes"></a>`#notes`

```ruby
attr_reader :notes
```

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(invocation:, notes:, error: nil, locked_bundler: nil)`](#method-i-initialize) |  |
| [`#failed?`](#method-i-failed-3F) |  |
| [`#skipped?`](#method-i-skipped-3F) |  |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(invocation:, notes:, error: nil, locked_bundler: nil)
```

### <a id="method-i-failed-3F"></a>`#failed?`

```ruby
def failed?
```

### <a id="method-i-skipped-3F"></a>`#skipped?`

```ruby
def skipped?
```
