require_relative "../../lib/rubies"

module Rubies
  describe Configuration do
    def capture_stderr(&block)
      old_stderr = $stderr
      $stderr = @stderr_string_io = StringIO.new
      block.call
    ensure
      $stderr = old_stderr
    end

    def stderr
      @stderr_string_io.string
    end

    around(:each) do |example|
      capture_stderr { example.run }
    end

    it "shows help when asked" do
      expect do
        Configuration.from_arguments("--help")
      end.to raise_error SystemExit
      expect(stderr).to match(/\AUsage:/)
    end

    describe "activate" do
      it "returns the arguments" do
        args = Configuration.from_arguments(["activate", "2.1.0", "."])
        expect(args).to eq(["activate", "2.1.0", "."])
        expect(stderr).to eq("")
      end

      it "requires exactly two arguments" do
        args_to_try = [
          [],
          ["2.1.0"],
          ["2.1.0", ".", "extra-arg"],
        ]
        args_to_try.each do |args|
          expect do
            Configuration.from_arguments(["activate"] + args)
          end.to raise_error(SystemExit)
          expect(stderr).to match(/wrong number of arguments for activate/)
        end
      end
    end

    describe "deactivate" do
      it "returns the name of the command" do
        args = Configuration.from_arguments(["deactivate"])
        expect(args).to eq(["deactivate"])
      end

      it "requires exactly zero arguments" do
        expect do
          Configuration.from_arguments(["deactivate", "extra-arg"])
        end.to raise_error(SystemExit)
        expect(stderr).to match(/deactivate doesn't take any arguments/)
      end
    end

    describe "ruby-info" do
      it "returns the name of the command" do
        args = Configuration.from_arguments(["ruby-info"])
        expect(args).to eq(["ruby-info"])
      end

      it "requires exactly zero arguments" do
        expect do
          Configuration.from_arguments(["ruby-info", "extra-arg"])
        end.to raise_error(SystemExit)
        expect(stderr).to match(/ruby-info doesn't take any arguments/)
      end
    end

    context "when no subcommand is given" do
      it "shows usage" do
        expect do
          Configuration.from_arguments([])
        end.to raise_error(SystemExit)
        expect(stderr).to match(/\AUsage:/)
      end
    end

    context "when an unknown subcommand is given" do
      it "shows usage" do
        expect do
          Configuration.from_arguments(["unknown-command"])
        end.to raise_error(SystemExit)
        expect(stderr).to match(/unknown-command is not a command/)
      end
    end

    context "when unknown arguments are given" do
      it "shows usage" do
        expect do
          Configuration.from_arguments(["--unknown-arg"])
        end.to raise_error(SystemExit)
        expect(stderr).to match(/invalid option: --unknown-arg/)
      end
    end
  end
end
