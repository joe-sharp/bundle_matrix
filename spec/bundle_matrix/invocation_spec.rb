# frozen_string_literal: true

RSpec.describe(BundleMatrix::Invocation) do
  def parse(*argv)
    described_class.parse(argv)
  end

  def thor_table(command)
    Bundler::CLI.class_options.merge(Bundler::CLI.commands.fetch(command).options)
  end

  # resolve_command is private to ArgvParser, and parse hides the name it resolved to
  def resolve(token)
    BundleMatrix::ArgvParser.send(:resolve_command, token)
  end

  describe "command name resolution" do
    it "returns exact command names", :aggregate_failures do
      expect(resolve("install")).to eq("install")
      expect(resolve("cache")).to eq("cache")
    end

    it "resolves unambiguous prefixes", :aggregate_failures do
      expect(resolve("ins")).to eq("install")
      expect(resolve("a")).to eq("add")
      expect(resolve("u")).to eq("update")
    end

    it "resolves aliases to their target", :aggregate_failures do
      expect(resolve("i")).to eq("install")
      expect(resolve("ls")).to eq("list")
    end

    it "returns nil for an ambiguous prefix", :aggregate_failures do
      expect(resolve("in")).to be_nil
      expect(parse("in")).to be_nil
    end

    # Bundler 2.6.9 matches hidden commands by prefix, and 4.x does not, so only the parse result is the same
    it "does not fan out for a hidden command reached by prefix" do
      expect(parse("install_or")).to be_nil
    end

    it "returns unknown names unchanged, for COMMANDS to filter out" do
      expect(resolve("zz")).to eq("zz")
    end

    it "returns nil when there is no token" do
      expect(resolve(nil)).to be_nil
    end
  end

  describe ".parse" do
    it "returns nil for commands bundle_matrix does not fan out", :aggregate_failures do
      expect(parse("exec", "rspec")).to be_nil
      expect(parse("check")).to be_nil
      expect(parse("zz")).to be_nil
    end

    it "treats `i` as install" do
      expect(parse("i").command).to eq("install")
    end

    it "accepts the unambiguous prefixes Bundler accepts", :aggregate_failures do
      expect(parse("ins").command).to eq("install")
      expect(parse("a", "rack").command).to eq("add")
      expect(parse("u").command).to eq("update")
      expect(parse("up").command).to eq("update")
    end

    it "splits gems from options", :aggregate_failures do
      invocation = parse("update", "rails", "--conservative", "rack")

      expect(invocation.gems).to eq(%w[rails rack])
      expect(invocation.option?("conservative")).to be(true)
    end

    it "forwards a dash-leading gem after -- so it is not read as a switch", :aggregate_failures do
      expect(parse("add", "--", "-weird").to_argv).to eq(%w[add -- -weird])
      expect(parse("add", "rack", "--", "-weird").to_argv).to eq(%w[add -- rack -weird])
    end

    it "keeps gems before the options when none starts with a dash" do
      expect(parse("update", "rails", "--conservative").to_argv).to eq(%w[update rails --conservative])
    end

    it "resolves aliases to the canonical option name", :aggregate_failures do
      invocation = parse("update", "-j", "4", "-g", "dev")

      expect(invocation.option?("jobs")).to be(true)
      expect(invocation.values("group")).to eq(%w[dev])
    end

    it "handles --name=value and short values attached to the flag", :aggregate_failures do
      expect(parse("install", "--jobs=4").values("jobs")).to eq(%w[4])
      expect(parse("install", "-j4").values("jobs")).to eq(%w[4])
    end

    it "lets array options consume values up to the next switch", :aggregate_failures do
      invocation = parse("update", "--group", "test", "dev", "--conservative", "rails")

      expect(invocation.values("group")).to eq(%w[test dev])
      expect(invocation.gems).to eq(%w[rails])
    end

    it "reads the values after an array option given inline with =", :aggregate_failures do
      invocation = parse("update", "--group=test", "dev", "--conservative", "rails")

      expect(invocation.values("group")).to eq(%w[test dev])
      expect(invocation.gems).to eq(%w[rails])
    end

    it "reads a repeated option the way Bundler does, from its last copy", :aggregate_failures do
      expect(parse("update", "--group", "dev", "--group", "test").values("group")).to eq(%w[test])
      expect(parse("add", "foo", "--path", "a", "--path", "b").values("path")).to eq(%w[b])
      expect(parse("update", "--all", "--no-all").option?("all")).to be(false)
    end

    it "does not count --no-name as setting the option, but still forwards it", :aggregate_failures do
      invocation = parse("update", "--no-all", "rails")

      expect(invocation.option?("all")).to be(false)
      expect(invocation.to_argv).to eq(%w[update rails --no-all])
    end

    it "still counts --no-color as setting the option, because it is a real option" do
      expect(parse("install", "--no-color").option?("no-color")).to be(true)
    end

    it "only consumes a value for a lazy-default option when one is present", :aggregate_failures do
      expect(parse("update", "--bundler", "--all").values("bundler")).to eq([])
      expect(parse("update", "--bundler", "4.0.1").values("bundler")).to eq(%w[4.0.1])
    end

    it "keeps unknown switches for forwarding" do
      expect(parse("install", "--some-future-flag").unknown).to eq(%w[--some-future-flag])
    end

    it "understands Bundler's global options, so their values are not read as gems", :aggregate_failures do
      expect(parse("install", "--retry", "3").values("retry")).to eq(%w[3])
      expect(parse("update", "-r", "3").values("retry")).to eq(%w[3])
      expect(parse("update", "--retry", "3").gems).to eq([])
      expect(parse("update", "--verbose", "--all").option?("verbose")).to be(true)
    end

    it "keeps global options when it is re-targeted at install", :aggregate_failures do
      forwarded = parse("update", "--retry", "3", "--all").as("install")

      expect(forwarded.to_argv).to eq(%w[install --retry 3])
    end

    it "treats everything after -- as a gem name" do
      expect(parse("add", "--strict", "--", "rails").gems).to eq(%w[rails])
    end

    # rubocop:disable-next RSpec/ExampleLength
    it "matches Thor's own parsing for the gems and options it recognises", :aggregate_failures do
      samples = [
        %w[update rails --conservative],
        %w[update --group test dev rails],
        %w[update --all --patch --jobs 2],
        %w[install --local --jobs=2 --standalone dev test],
        %w[add rails -v 1.0 -g dev --strict],
        %w[add rails --skip-install],
        %w[install --retry 3 --jobs 2],
        %w[update --verbose --all],
        %w[update --group=test dev --conservative rails]
      ]

      no_values = [true, false, nil]

      samples.each do |argv|
        command, *tokens = argv
        thor = Bundler::Thor::Options.new(thor_table(command))
        thor_options = thor.parse(tokens)
        invocation = parse(*argv)

        expect(invocation.gems).to eq(Array(thor.remaining)), "gems differ for #{argv.join(" ")}"
        expect(invocation.options.map(&:name)).to(
          match_array(thor_options.keys.map(&:to_s)), "options differ for #{argv.join(" ")}"
        )
        thor_options.each do |name, value|
          next if no_values.include?(value)

          expect(invocation.values(name.to_s)).to eq(Array(value).map(&:to_s)),
            "values differ for --#{name} in #{argv.join(" ")}"
        end
      end
    end
  end

  describe "when no command is given" do
    before do
      allow(Bundler.settings).to receive(:[]).and_call_original
      allow(Bundler.settings).to receive(:[]).with(:default_cli_command).and_return(nil)
    end

    def default_command_is(name)
      allow(Bundler.settings).to receive(:[]).with(:default_cli_command).and_return(name)
    end

    it "fans out a bare bundle as install" do
      expect(parse).to have_attributes(command: "install", gems: [])
    end

    it "fans out switches as install options", :aggregate_failures do
      invocation = parse("--jobs=4")

      expect(invocation.command).to eq("install")
      expect(invocation.values("jobs")).to eq(%w[4])
      expect(invocation.to_argv).to eq(%w[install --jobs=4])
    end

    it "fans out when default_cli_command is install" do
      default_command_is("install")

      expect(parse("--jobs=4").command).to eq("install")
    end

    it "fans out when default_cli_command is install_or_cli_help, which Bundler runs as install" do
      skip "this Bundler has no install_or_cli_help" unless Bundler::CLI.all_commands.key?("install_or_cli_help")

      default_command_is("install_or_cli_help")

      expect(parse("--jobs=4").command).to eq("install")
    end

    it "does not fan out when default_cli_command is cli_help, which only prints help", :aggregate_failures do
      default_command_is("cli_help")

      expect(parse).to be_nil
      expect(parse("--jobs=4")).to be_nil
    end

    it "does not treat a mapped switch such as -v as the default command" do
      expect(parse("-v")).to be_nil
    end

    # Bundler rejects this form before any hook runs, so it never fans out. Parsing it the same way keeps us honest.
    it "reads a command after leading switches as an argument, as Bundler does" do
      expect(parse("--verbose", "install").to_argv).to eq(%w[install install --verbose])
    end
  end

  describe "#to_argv" do
    it "re-emits every token the user supplied" do
      argv = %w[update rails --conservative --group test dev --bundler 4.0.1 --unknown-thing]

      expect(parse(*argv).to_argv).to eq(argv)
    end
  end

  describe "#as" do
    # rubocop:disable-next RSpec/ExampleLength
    it "keeps only the options the target command understands", :aggregate_failures do
      invocation = parse("update", "rails", "--conservative", "--group", "dev", "--jobs", "2")
      install = invocation.as("install")

      expect(install.command).to eq("install")
      expect(install.gems).to eq([])
      expect(install.option?("conservative")).to be(false)
      expect(install.option?("group")).to be(false)
      expect(install.option?("jobs")).to be(true)
    end
  end
end
