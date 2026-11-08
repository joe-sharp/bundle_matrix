# Module: BundleMatrix::Hook

- **Defined in:** [`lib/bundle_matrix/hook.rb`](../../lib/bundle_matrix/hook.rb)

Called by Bundler after `install`, `update` or `add` has finished.

## Class methods

| Method | Summary |
| --- | --- |
| [`.call(argv = ARGV)`](#method-c-call) | Checked before parsing, so a disabled plugin or a child run never depends on how Bundler's CLI parses |

### <a id="method-c-call"></a>`.call`

```ruby
def self.call(argv = ARGV)
```

Checked before parsing, so a disabled plugin or a child run never depends on how Bundler's CLI parses
