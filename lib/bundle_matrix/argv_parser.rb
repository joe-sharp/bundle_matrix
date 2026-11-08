# frozen_string_literal: true

require "bundler/cli"

module BundleMatrix
  # Finds the command in argv the way Bundler does, then splits the tokens after it into
  # options, gems and unknown switches, using the switch table Bundler itself uses for that command.
  # Every touch of Bundler::CLI is in this class, so the rest of the plugin only sees command names and tokens.
  class ArgvParser
    Switch = Data.define(:name, :option, :negated)

    # One switch Bundler accepts for a command; negated is true for its `--no-name` form
    class Switch
      def initialize(name:, option:, negated: false)
        super
      end
    end

    INSTALL_ALIASES = %w[install install_or_cli_help].freeze

    # @return [Array(String, Array<String>)] the command Bundler would run (nil when unknown) and the tokens after it
    def self.split_command(argv)
      first, *rest = argv
      return [resolve_command(first), rest] unless default_command_used?(first)

      command = resolve_command(Bundler.settings[:default_cli_command] || "install")
      # Bundler runs install for its deprecated install_or_cli_help alias too
      [INSTALL_ALIASES.include?(command) ? "install" : command, argv]
    end

    # Bundler runs its default command when argv is empty or starts with a switch
    # (`bundle`, `bundle --jobs=4`), and then every token is an argument. A mapped
    # switch such as `-v` is still a command of its own. With default_cli_command unset,
    # Bundler 4 still runs install here, with a notice that this will change. Its docs
    # already name cli_help as the default, but the code does not, so this follows the code.
    # The setting is read directly, because Bundler::CLI.default_command prints that notice again.
    def self.default_command_used?(token)
      token.nil? || (token.start_with?("-") && !Bundler::CLI.map.key?(token))
    end
    private_class_method :default_command_used?

    # Thor has no public method for prefix lookup (`i`, `ins`, `a`, `u`), so this calls its protected
    # normalize_command_name. The code already relies on Thor's tables, and calling the method keeps
    # the result identical to Bundler's, where a copy could drift without anyone noticing.
    def self.resolve_command(token)
      return unless token

      Bundler::CLI.send(:normalize_command_name, token)
    rescue Bundler::Thor::AmbiguousTaskError
      # Bundler rejects an ambiguous name before installing, so the hook never sees one. This is only a safeguard.
      nil
    end
    private_class_method :resolve_command

    # @return [Array(Array<Invocation::Option>, Array<String>, Array<String>)]
    def self.call(command, tokens)
      new(table_for(command)).call(tokens)
    end

    # Bundler's global options (--retry, --verbose, --no-color) apply to every command, so they are added to its own.
    # Thor's tables are not a plugin API, so a Bundler release can change them; the Appraisals cover each version.
    def self.table_for(command)
      Bundler::CLI.class_options.merge(Bundler::CLI.commands.fetch(command).options)
    end

    def initialize(table)
      @switches = switch_table(table)
    end

    def call(tokens)
      switch_tokens, literal_gems = split_terminator(tokens)
      options, gems, unknown = collect(switch_tokens.dup)
      [options, gems + literal_gems, unknown]
    end

    private

    def collect(rest)
      options = []
      gems = []
      unknown = []

      until rest.empty?
        token = rest.shift
        next gems << token unless switch?(token)

        option = read_option(token, rest)
        option ? options << option : unknown << token
      end

      [options, gems, unknown]
    end

    def switch_table(table)
      switches = table.each_with_object({}) do |(name, option), lookup|
        lookup["--#{name}"] = Switch.new(name: name, option: option)
        option.aliases.each { |alias_name| lookup[alias_name] = Switch.new(name: name, option: option) }
      end

      table.each do |name, option|
        next unless option.type == :boolean

        switches["--no-#{name}"] ||= Switch.new(name: name, option: option, negated: true)
      end

      switches
    end

    def switch?(token)
      token.start_with?("-") && token != "-"
    end

    # Everything after a bare `--` is a gem name, whatever it looks like
    def split_terminator(tokens)
      index = tokens.index("--")
      return [tokens, []] unless index

      [tokens.take(index), tokens.drop(index + 1)]
    end

    # Consumes the values that belong to a switch from the front of rest
    def read_option(token, rest)
      key, inline = split_switch(token)
      switch = @switches[key]
      return unless switch

      values, used = values_for(switch.option, inline, rest)
      Invocation::Option.new(
        name: switch.name, tokens: [token, *rest.shift(used)], values: values, negated: switch.negated
      )
    end

    # `--name=value`, and `-jvalue` for single-dash switches
    def split_switch(token)
      key, separator, value = token.partition("=")
      value = nil if separator.empty?
      return [key, value] if @switches.key?(key) || !token.match?(/\A-[^-]/)

      short = token[0, 2].to_s
      @switches.key?(short) ? [short, token[2..]] : [key, value]
    end

    # @return [Array(Array<String>, Integer)] the values and how many following tokens they used
    def values_for(option, inline, rest)
      return array_values(rest, [inline]) if option.type == :array && inline
      return [[inline], 0] if inline
      return [[], 0] if option.type == :boolean
      return array_values(rest, []) if option.type == :array
      return [[], 0] if rest.empty? || (option.lazy_default && switch?(rest.first))

      [[rest.first], 1]
    end

    # An array option takes every value up to the next switch, after any value given inline with `=`
    def array_values(rest, leading)
      values = rest.take_while { |token| !switch?(token) }
      [leading + values, values.size]
    end
  end
end
