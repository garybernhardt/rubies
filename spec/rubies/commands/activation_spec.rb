require_relative "../../../lib/rubies"

module Rubies
  describe 'activation' do
    let(:ruby_info) { RubyInfo.new(:ruby_engine => "ruby",
                                   :ruby_version => "2.1.0",
                                   :bin_dir => "/usr/local/bin",
                                   :gem_path => "/lib/gems") }
    let(:new_env) { Commands.activate(env, ruby_info, "ruby-2.1.0", "/myproj") }

    context "when no ruby is activated" do
      let(:env) { Environment.new(:path => "/usr/bin:/bin",
                                  :current_gem_home => nil,
                                  :current_gem_path => nil,
                                  :activated_ruby_bin => nil,
                                  :activated_sandbox_bin => nil) }

      it "adds the Ruby and gem bin paths to the PATH" do
        new_env.path.should == ["/myproj/.gem/ruby/2.1.0/bin",
                                "/usr/local/bin",
                                "/usr/bin",
                                "/bin"].join(":")
      end

      it "sets gem environment variables" do
        new_env.current_gem_home.should == "/myproj/.gem/ruby/2.1.0"
        new_env.current_gem_path.should == "/myproj/.gem/ruby/2.1.0:/lib/gems"
      end

      it "saves the current activated bin paths for later" do
        new_env.activated_ruby_bin.should == "/usr/local/bin"
        new_env.activated_sandbox_bin.should == "/myproj/.gem/ruby/2.1.0/bin"
      end
    end

    context "when a ruby is already activated" do
      let(:env) { Environment.new(:path => "/usr/bin:/bin",
                                  :current_gem_home => "/myproj/.gems",
                                  :current_gem_path => "/lib/gems:/myproj/.gems",
                                  :activated_ruby_bin => "/usr/local/bin",
                                  :activated_sandbox_bin => "/myproj/.gems/bin") }

      it "removes any previous activation's PATH entries" do
        env.activated_ruby_bin = "/usr/local/otherruby/bin"
        env.activated_sandbox_bin = "/otherproj/.gems/bin"
        env.path = [env.activated_sandbox_bin,
                    env.activated_ruby_bin,
                    env.path].join(":")
        new_env.path.should_not include env.activated_ruby_bin
        new_env.path.should_not include env.activated_sandbox_bin
      end
    end
  end
end
