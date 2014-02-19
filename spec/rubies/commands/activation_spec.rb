require_relative "../../../lib/rubies"

module Rubies
  describe 'activation' do
    let(:env) { Environment.new("/usr/bin:/bin",
                                "/myproj/.gems",
                                "/lib/gems:/myproj/.gems",
                                "/usr/local/bin",
                                "/myproj/.gems/bin") }
    let(:ruby_info) { RubyInfo.new("ruby",
                                   "2.1.0",
                                   "/usr/local/bin",
                                   "/lib/gems") }
    let(:new_vars) { Commands.activate(env, ruby_info, "ruby-2.1.0", "/myproj") }
    let(:expected_bin) { ["/myproj/.gem/ruby/2.1.0/bin",
                          "/usr/local/bin",
                          "/usr/bin",
                          "/bin"].join(":") }

    it "adds the Ruby and gem bin paths to the PATH" do
      new_vars.fetch("PATH").should == expected_bin
    end

    it "removes any previous activation's PATH entries" do
      env.activated_ruby_bin = "/usr/local/otherruby/bin"
      env.activated_sandbox_bin = "/otherproj/.gems/bin"
      env.current_path = [env.activated_sandbox_bin,
                          env.activated_ruby_bin,
                          env.current_path].join(":")
      new_vars = Commands.activate(env, ruby_info, "ruby-2.1.0", "/myproj")
      new_vars.fetch("PATH").should == expected_bin
    end

    it "sets gem environment variables"
    it "sets current activated Ruby variables"
  end
end