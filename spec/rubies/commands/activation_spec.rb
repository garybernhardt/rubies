require_relative "../../../lib/rubies"

module Rubies
  describe 'activation' do
    let(:env) { Environment.new(:current_path => "/usr/bin:/bin",
                                :current_gem_home => "/myproj/.gems",
                                :current_gem_path => "/lib/gems:/myproj/.gems",
                                :activated_ruby_bin => "/usr/local/bin",
                                :activated_sandbox_bin => "/myproj/.gems/bin") }
    let(:ruby_info) { RubyInfo.new(:ruby_engine => "ruby",
                                   :ruby_version => "2.1.0",
                                   :bin_path => "/usr/local/bin",
                                   :gem_path => "/lib/gems") }
    let(:new_vars) { Commands.activate(env, ruby_info, "ruby-2.1.0", "/myproj") }

    it "adds the Ruby and gem bin paths to the PATH" do
      new_vars.fetch("PATH").should == ["/myproj/.gem/ruby/2.1.0/bin",
                                        "/usr/local/bin",
                                        "/usr/bin",
                                        "/bin"].join(":")
    end

    it "removes any previous activation's PATH entries" do
      env.activated_ruby_bin = "/usr/local/otherruby/bin"
      env.activated_sandbox_bin = "/otherproj/.gems/bin"
      env.current_path = [env.activated_sandbox_bin,
                          env.activated_ruby_bin,
                          env.current_path].join(":")
      new_path = new_vars.fetch("PATH")
      new_path.should_not include env.activated_ruby_bin
      new_path.should_not include env.activated_sandbox_bin
    end

    it "sets gem environment variables"
    it "sets current activated Ruby variables"
  end
end
