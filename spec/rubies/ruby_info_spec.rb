require "rubies"

module Rubies
  describe RubyInfo do
    it "gets information for the default Ruby on the path" do
      info = RubyInfo.from_whichever_ruby_is_in_the_path
      expect(info.ruby_engine).to eq("ruby")
      expect(info.ruby_version).to eq(RUBY_VERSION)
      expect(info.gem_path).to eq(Gem.path.join(':'))
    end

    it "gets information from specific ruby bin paths" do
      # This doesn't really test executing a Ruby other than the one we're
      # running in; that would require an entire Ruby installation as a fixture
      current_ruby_bin_dir = RbConfig::CONFIG.fetch('bindir')
      info = RubyInfo.from_bin_dir(current_ruby_bin_dir)
      expect(info.ruby_engine).to eq("ruby")
      expect(info.ruby_version).to eq(RUBY_VERSION)
      expect(info.gem_path).to eq(Gem.path.join(':'))
    end

    it "gets information from this ruby" do
      info = RubyInfo.from_this_ruby_process
      expect(info.ruby_engine).to eq("ruby")
      expect(info.ruby_version).to eq(RUBY_VERSION)
      expect(info.gem_path).to eq(Gem.path.join(':'))
    end
  end
end
