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
        expect(env.path).to eq("path")
        expect(env.current_gem_home).to eq("/gem/home")
        expect(env.current_gem_path).to eq("/gem/path")
        expect(env.activated_ruby_bin).to eq("/ruby/bin")
        expect(env.activated_ruby_name).to eq("2.1.0")
        expect(env.activated_sandbox_bin).to eq("/sandbox/bin")
      end

      it "uses nil in place of missing keys" do
        env = Environment.from_system_environment({})
        expect(env.path).to eq(nil)
        expect(env.current_gem_home).to eq(nil)
        expect(env.current_gem_path).to eq(nil)
        expect(env.activated_ruby_bin).to eq(nil)
        expect(env.activated_ruby_name).to eq(nil)
        expect(env.activated_sandbox_bin).to eq(nil)
      end
    end

    describe "converting to shell commands" do
      it "sets variables that are present and unsets variables that are missing" do
        env = Environment.from_system_environment(
          "PATH" => "/path",
          "GEM_HOME" => "/gem/home")
        expect(env.to_shell_commands).to eq(%{\
export GEM_HOME="/gem/home"
unset GEM_PATH
export PATH="/path"
unset RUBIES_ACTIVATED_RUBY_BIN_DIR
unset RUBIES_ACTIVATED_RUBY_NAME
unset RUBIES_ACTIVATED_SANDBOX_BIN_DIR
rehash})
      end
    end

    describe "PATH" do
      it "can remove directories from PATH" do
        env = Environment.from_system_environment(
          "PATH" => "/usr/local/bin:/usr/bin:/sbin:/bin")
        path = env.remove_dirs_from_path(["/usr/bin", "/bin"])
        expect(path).to eq("/usr/local/bin:/sbin")
      end
    end
  end
end
