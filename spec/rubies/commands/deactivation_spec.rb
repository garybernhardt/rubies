require_relative "../../../lib/rubies"

module Rubies
  describe "deactivation" do
    let(:env) { Environment.new(:path => "/myproj/.gems/bin:/usr/local/bin:/bin",
                                :current_gem_home => "/myproj/.gems",
                                :current_gem_path => "/lib/gems:/myproj/.gems",
                                :activated_ruby_bin => "/usr/local/bin",
                                :activated_ruby_name => "2.1.0",
                                :activated_sandbox_bin => "/myproj/.gems/bin") }
    let(:ruby_info) { RubyInfo.new(:ruby_engine => "ruby",
                                   :ruby_version => "2.1.0",
                                   :bin_dir => "/usr/local/bin",
                                   :gem_path => "/lib/gems") }
    let(:new_env) { Commands.deactivate(env, ruby_info) }

    it "removes the Ruby and gem bin paths from PATH" do
      new_env.path.should == "/bin"
    end

    it "unsets all other variables" do
      new_env.current_gem_home.should == nil
      new_env.current_gem_path.should == nil
      new_env.activated_ruby_bin.should == nil
      new_env.activated_ruby_name.should == nil
      new_env.activated_sandbox_bin.should == nil
    end
  end
end
