require "rubies"

module Rubies
  describe RubyInfo do
    it "gets information for the default Ruby on the path" do
      info = RubyInfo.from_whichever_ruby_is_in_the_path
      info.ruby_engine.should == "ruby"
      info.ruby_version.should == RUBY_VERSION
      info.gem_path.should == Gem.path.join(':')
    end

    it "gets information from specific ruby bin paths" do
      # This doesn't really test executing a Ruby other than the one we're
      # running in; that would require an entire Ruby installation as a fixture
      current_ruby_bin_dir = RbConfig::CONFIG.fetch('bindir')
      info = RubyInfo.from_bin_dir(current_ruby_bin_dir)
      info.ruby_engine.should == "ruby"
      info.ruby_version.should == RUBY_VERSION
      info.gem_path.should == Gem.path.join(':')
    end
  end
end
