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
      stderr.should =~ /\AUsage:/
    end

    describe "activate" do
      it "returns the arguments" do
        args = Configuration.from_arguments(["activate", "2.1.0", "."])
        args.should == ["activate", "2.1.0", "."]
        stderr.should == ""
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
          stderr.should =~ /wrong number of arguments for activate/
        end
      end
    end

    describe "deactivate" do
      it "returns the name of the command" do
        args = Configuration.from_arguments(["deactivate"])
        args.should == ["deactivate"]
      end

      it "requires exactly zero arguments" do
        expect do
          Configuration.from_arguments(["deactivate", "extra-arg"])
        end.to raise_error(SystemExit)
        stderr.should =~ /deactivate doesn't take any arguments/
      end
    end

    describe "ruby-info" do
      it "returns the name of the command" do
        args = Configuration.from_arguments(["ruby-info"])
        args.should == ["ruby-info"]
      end

      it "requires exactly zero arguments" do
        expect do
          Configuration.from_arguments(["ruby-info", "extra-arg"])
        end.to raise_error(SystemExit)
        stderr.should =~ /ruby-info doesn't take any arguments/
      end
    end

    context "when no subcommand is given" do
      it "shows usage" do
        expect do
          Configuration.from_arguments([])
        end.to raise_error(SystemExit)
        stderr.should =~ /\AUsage:/
      end
    end

    context "when an unknown subcommand is given" do
      it "shows usage" do
        expect do
          Configuration.from_arguments(["unknown-command"])
        end.to raise_error(SystemExit)
        stderr.should =~ /unknown-command is not a command/
      end
    end

    context "when unknown arguments are given" do
      it "shows usage" do
        expect do
          Configuration.from_arguments(["--unknown-arg"])
        end.to raise_error(SystemExit)
        stderr.should =~ /invalid option: --unknown-arg/
      end
    end
  end
end
