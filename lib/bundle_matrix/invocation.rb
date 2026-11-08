# frozen_string_literal: true

module BundleMatrix
  # A parsed `bundle install|update|add` command line.
  #
  # Option names, aliases and value types come from Bundler's own Thor tables,
  # so every flag Bundler accepts is understood, and the raw tokens are kept
  # so they can be forwarded exactly as the user typed them.
  class Invocation < Data.define(:command, :options, :gems, :unknown)
    COMMANDS = %w[install update add].freeze

    Option = Data.define(:name, :tokens, :values, :negated)

    # negated is true for a `--no-name` switch, which unsets the option rather than setting it
    class Option
      def initialize(name:, tokens:, values:, negated: false)
        super
      end
    end

    # @return [Invocation, nil] nil when the command is not one we fan out
    def self.parse(argv)
      command, tokens = ArgvParser.split_command(argv)
      return unless command && COMMANDS.include?(command)

      options, gems, unknown = ArgvParser.call(command, tokens)
      new(command: command, options: options, gems: gems, unknown: unknown)
    end

    # `--no-name` does not count as setting the option
    def option?(name)
      opt = option(name)
      !opt.nil? && !opt.negated
    end

    # Bundler keeps the last copy of a repeated option, so that is the one that counts
    def option(name)
      options.reverse_each.find { |opt| opt.name == name }
    end

    def values(name)
      option(name)&.values || []
    end

    def with_gems(new_gems)
      with(gems: new_gems)
    end

    def without(*names)
      with(options: options.reject { |opt| names.include?(opt.name) })
    end

    # Replaces an option's values, dropping the option when none are left.
    def replace_values(name, new_values)
      rest = without(name)
      return rest if new_values.empty?

      added = Option.new(name: name, tokens: ["--#{name}", *new_values], values: new_values)
      rest.with(options: rest.options + [added])
    end

    # The same flags, re-targeted at another command. Only options that command
    # understands are kept, and the gems are replaced.
    def as(target, gems: [])
      table = ArgvParser.table_for(target)
      with(command: target, options: options.select { |opt| table.key?(opt.name) }, gems: gems, unknown: [])
    end

    def to_argv
      [command, *gems, *options.flat_map(&:tokens), *unknown]
    end
  end
end
