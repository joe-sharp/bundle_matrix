# Class: BundleMatrix::Invocation

- **Inherits:** `Data.define(:command, :options, :gems, :unknown)`
- **Defined in:** [`lib/bundle_matrix/invocation.rb`](../../lib/bundle_matrix/invocation.rb)

A parsed `bundle install|update|add` command line.

Option names, aliases and value types come from Bundler's own Thor tables,
so every flag Bundler accepts is understood, and the raw tokens are kept
so they can be forwarded exactly as the user typed them.

## Namespaces

- [`BundleMatrix::Invocation::Option`](Invocation/Option.md) — negated is true for a `--no-name` switch, which unsets the option rather than setting it

## Constants

### <a id="constant-COMMANDS"></a>`COMMANDS`

```ruby
COMMANDS = %w[install update add].freeze
```

## Class methods

| Method | Summary |
| --- | --- |
| [`.parse(argv)`](#method-c-parse) | Returns nil when the command is not one we fan out |

### <a id="method-c-parse"></a>`.parse`

```ruby
def self.parse(argv)
```

**Returns:**

- ([`Invocation`](Invocation.md), `nil`) — nil when the command is not one we fan out

## Instance methods

| Method | Summary |
| --- | --- |
| [`#as(target, gems: [])`](#method-i-as) | The same flags, re-targeted at another command. |
| [`#option(name)`](#method-i-option) | Bundler keeps the last copy of a repeated option, so that is the one that counts |
| [`#option?(name)`](#method-i-option-3F) | `--no-name` does not count as setting the option |
| [`#replace_values(name, new_values)`](#method-i-replace_values) | Replaces an option's values, dropping the option when none are left. |
| [`#to_argv`](#method-i-to_argv) |  |
| [`#values(name)`](#method-i-values) |  |
| [`#with_gems(new_gems)`](#method-i-with_gems) |  |
| [`#without(*names)`](#method-i-without) |  |

### <a id="method-i-as"></a>`#as`

```ruby
def as(target, gems: [])
```

The same flags, re-targeted at another command. Only options that command
understands are kept, and the gems are replaced.

### <a id="method-i-option"></a>`#option`

```ruby
def option(name)
```

Bundler keeps the last copy of a repeated option, so that is the one that counts

### <a id="method-i-option-3F"></a>`#option?`

```ruby
def option?(name)
```

`--no-name` does not count as setting the option

### <a id="method-i-replace_values"></a>`#replace_values`

```ruby
def replace_values(name, new_values)
```

Replaces an option's values, dropping the option when none are left.

### <a id="method-i-to_argv"></a>`#to_argv`

```ruby
def to_argv
```

### <a id="method-i-values"></a>`#values`

```ruby
def values(name)
```

### <a id="method-i-with_gems"></a>`#with_gems`

```ruby
def with_gems(new_gems)
```

### <a id="method-i-without"></a>`#without`

```ruby
def without(*names)
```
