# Class: BundleMatrix::ArgvParser

- **Defined in:** [`lib/bundle_matrix/argv_parser.rb`](../../lib/bundle_matrix/argv_parser.rb)

Finds the command in argv the way Bundler does, then splits the tokens after it into
options, gems and unknown switches, using the switch table Bundler itself uses for that command.
Every touch of Bundler::CLI is in this class, so the rest of the plugin only sees command names and tokens.

## Namespaces

- [`BundleMatrix::ArgvParser::Switch`](ArgvParser/Switch.md) — One switch Bundler accepts for a command; negated is true for its `--no-name` form

## Constants

### <a id="constant-INSTALL_ALIASES"></a>`INSTALL_ALIASES`

```ruby
INSTALL_ALIASES = %w[install install_or_cli_help].freeze
```

## Class methods

| Method | Summary |
| --- | --- |
| [`.call(command, tokens)`](#method-c-call) |  |
| [`.split_command(argv)`](#method-c-split_command) | Returns the command Bundler would run (nil when unknown) and the tokens after it |
| [`.table_for(command)`](#method-c-table_for) | Bundler's global options (--retry, --verbose, --no-color) apply to every command, so they are added to its own. |

### <a id="method-c-call"></a>`.call`

```ruby
def self.call(command, tokens)
```

**Returns:**

- (`Array(Array<`[`Invocation::Option`](Invocation/Option.md)`>, Array<String>, Array<String>)`)

### <a id="method-c-split_command"></a>`.split_command`

```ruby
def self.split_command(argv)
```

**Returns:**

- (`Array(String, Array<String>)`) — the command Bundler would run (nil when unknown) and the tokens after it

### <a id="method-c-table_for"></a>`.table_for`

```ruby
def self.table_for(command)
```

Bundler's global options (--retry, --verbose, --no-color) apply to every command, so they are added to its own.
Thor's tables are not a plugin API, so a Bundler release can change them; the Appraisals cover each version.

## Instance methods

| Method | Summary |
| --- | --- |
| [`#initialize(table)`](#method-i-initialize) |  |
| [`#call(tokens)`](#method-i-call) |  |

### <a id="method-i-initialize"></a>`#initialize`

```ruby
def initialize(table)
```

### <a id="method-i-call"></a>`#call`

```ruby
def call(tokens)
```
