require "rubies"

module Rubies
  describe Environment do
    describe "constructed from a Unix environment" do
      it "translates Unix environment keys to our keys" do
        env = Environment.from_system_environment(
          "PATH" => "path",
          "GEM_HOME" => "/gem/home",
          "GEM_PATH" => "/gem/path",
          "RUBIES_ACTIVATED_RUBY_NAME" => "2.1.0",
          "RUBIES_ACTIVATED_RUBY_BIN_DIR" => "/ruby/bin",
          "RUBIES_ACTIVATED_SANDBOX_BIN_DIR" => "/sandbox/bin")
        env.path.should == "path"
        env.current_gem_home.should == "/gem/home"
        env.current_gem_path.should == "/gem/path"
        env.activated_ruby_bin.should == "/ruby/bin"
        env.activated_ruby_name.should == "2.1.0"
        env.activated_sandbox_bin.should == "/sandbox/bin"
      end

      it "uses nil in place of missing keys" do
        env = Environment.from_system_environment({})
        env.path.should == nil
        env.current_gem_home.should == nil
        env.current_gem_path.should == nil
        env.activated_ruby_bin.should == nil
        env.activated_ruby_name.should == nil
        env.activated_sandbox_bin.should == nil
      end
    end

    describe "converting to shell commands" do
      it "sets variables that are present and unsets variables that are missing" do
        env = Environment.from_system_environment(
          "PATH" => "/path",
          "GEM_HOME" => "/gem/home")
        env.to_shell_commands.should == %{\
export GEM_HOME="/gem/home"
unset GEM_PATH
export PATH="/path"
unset RUBIES_ACTIVATED_RUBY_BIN_DIR
unset RUBIES_ACTIVATED_RUBY_NAME
unset RUBIES_ACTIVATED_SANDBOX_BIN_DIR
rehash}
      end
    end

    describe "PATH" do
      it "can remove directories from PATH" do
        env = Environment.from_system_environment(
          "PATH" => "/usr/local/bin:/usr/bin:/sbin:/bin")
        path = env.remove_dirs_from_path(["/usr/bin", "/bin"])
        path.should == "/usr/local/bin:/sbin"
      end
    end
  end
end
