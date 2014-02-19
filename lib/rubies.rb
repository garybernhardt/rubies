#!/usr/bin/env ruby
require 'rubygems'

module Rubies
  def self.main
    case ARGV.fetch(0)
    when 'ruby-info' then Rubies::Commands.ruby_info
    when 'activate'
      ruby_name = ARGV.fetch(1)
      sandbox = ARGV.fetch(2)
      ruby_bin = File.expand_path("~/.rubies/#{ruby_name}/bin")
      Rubies::Commands.activate!(Rubies::Environment.from_system_environment(ENV),
                                 Rubies::RubyInfo.from_bin_dir(ruby_bin),
                                 ruby_name,
                                 sandbox)
    when 'deactivate' then Rubies::Commands.deactivate!
    else raise ArgumentError.new("No subcommand given")
    end
  end

  module Commands
    def self.activate!(env, ruby_info, ruby_name, sandbox)
      puts activate(env, ruby_info, ruby_name, sandbox).to_shell_commands
    end

    def self.activate(env, ruby_info, ruby_name, sandbox)
      sandbox = File.expand_path(sandbox)
      sandboxed_gems = "#{sandbox}/.gem/#{ruby_info.ruby_engine}/#{ruby_info.ruby_version}"
      sandboxed_bin = "#{sandboxed_gems}/bin"

      path = env.remove_dirs_from_path([env.activated_ruby_bin,
                                        env.activated_sandbox_bin])

      Environment.new(
        :path => "#{sandboxed_bin}:#{ruby_info.bin_dir}:#{path}",
        :current_gem_home => "#{sandboxed_gems}",
        :current_gem_path => "#{sandboxed_gems}:#{ruby_info.gem_path}",
        :activated_ruby_bin => ruby_info.bin_dir,
        :activated_sandbox_bin => sandboxed_bin)
    end

    def self.deactivate!
      puts deactivate.to_shell_commands
    end

    def self.deactivate
      ruby_info = RubyInfo.from_whichever_ruby_is_in_the_path
      env = Environment.from_system_environment(ENV)
      restored_path = env.remove_dirs_from_path([env.activated_ruby_bin,
                                                 env.activated_sandbox_bin])
      Environment.new(
        :path => restored_path,
        :current_gem_home => nil,
        :current_gem_path => nil,
        :activated_ruby_bin => nil,
        :activated_sandbox_bin => nil)
    end

    def self.ruby_info
      ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
      ruby_version = RUBY_VERSION
      bin_dir = RbConfig::CONFIG.fetch("bindir")
      gem_path = Gem.path.join(':')

      puts [ruby_engine, ruby_version, bin_dir, gem_path].join("\n")
    end
  end

  class StrictStruct < Struct
    def initialize(params)
      super(*self.class.members.map { |member| params.fetch(member.to_sym) })
    end

    def merge(params)
      self.class.new(to_h.merge(params))
    end

    # Newer rubies have this; older rubies don't
    def to_h
      Hash[members.map(&:to_sym).zip(values)]
    end
  end

  class Environment < StrictStruct.new(:path,
                                       :current_gem_home,
                                       :current_gem_path,
                                       :activated_ruby_bin,
                                       :activated_sandbox_bin)

    SHELL_KEYS = {
      :path => "PATH",
      :current_gem_home => "GEM_HOME",
      :current_gem_path => "GEM_PATH",
      :activated_ruby_bin => "RUBIES_ACTIVATED_RUBY_BIN_DIR",
      :activated_sandbox_bin => "RUBIES_ACTIVATED_SANDBOX_BIN_DIR",
    }

    def self.from_system_environment(unix_env)
      keys = members.map(&:to_sym)
      values = keys.map do |key|
        shell_key = SHELL_KEYS.fetch(key)
        unix_env.fetch(shell_key) { nil }
      end
      new(Hash[keys.zip(values)])
    end

    def to_shell_commands
      unix_vars = self.to_h.map do |k, v|
        k = SHELL_KEYS.fetch(k)
        [k, v]
      end
      unix_vars.sort.map do |k, v|
        if v.nil?
          %{unset #{k}}
        else
          %{export #{k}="#{v}"}
        end
      end.join("\n")
    end

    def remove_dirs_from_path(dirs_to_remove)
      (self.path.split(/:/) - dirs_to_remove).join(":")
    end
  end

  class RubyInfo < StrictStruct.new(:ruby_engine,
                                    :ruby_version,
                                    :bin_dir,
                                    :gem_path)

    def self.from_whichever_ruby_is_in_the_path
      from_ruby_command("ruby")
    end

    def self.from_bin_dir(ruby_bin_dir)
      from_ruby_command("#{ruby_bin_dir}/ruby")
    end

    # Fork off a new Ruby to grab its version, gem path, etc.
    def self.from_ruby_command(ruby_command)
      cmd = "#{ruby_command} #{File.expand_path(__FILE__)} ruby-info"
      ruby_info_string = `#{cmd}`
      unless $?.success?
        raise RuntimeError.new("Failed to get Ruby info; this is a bug!") 
      end

      ruby_info = ruby_info_string.split(/\n/)
      unless ruby_info.length == RubyInfo.members.length
        raise RuntimeError.new("Ruby info had wrong length; this is a bug!")
      end

      new(:ruby_engine => ruby_info.fetch(0),
          :ruby_version => ruby_info.fetch(1),
          :bin_dir => ruby_info.fetch(2),
          :gem_path => ruby_info.fetch(3))
    end
  end
end

Rubies.main if __FILE__ == $0
