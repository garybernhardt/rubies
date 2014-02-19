#!/usr/bin/env ruby
require 'rubygems'

module Rubies
  module Commands
    def self.activate!(env, ruby_info, ruby_name, sandbox)
      Rubies.emit_vars!(activate(env, ruby_info, ruby_name, sandbox))
    end

    def self.activate(env, ruby_info, ruby_name, sandbox)
      sandbox = File.expand_path(sandbox)
      sandboxed_gems = "#{sandbox}/.gem/#{ruby_info.ruby_engine}/#{ruby_info.ruby_version}"
      sandboxed_bin = "#{sandboxed_gems}/bin"

      current_path = Rubies.remove_from_PATH(env.current_path,
                                             [env.activated_ruby_bin,
                                              env.activated_sandbox_bin])

      {
        "PATH" => "#{sandboxed_bin}:#{ruby_info.bin_dir}:#{current_path}",
        "GEM_HOME" => "#{sandboxed_gems}",
        "GEM_PATH" => "#{sandboxed_gems}:#{ruby_info.gem_path}",
        "RUBIES_ACTIVATED_RUBY_BIN_DIR" => ruby_info.bin_dir,
        "RUBIES_ACTIVATED_SANDBOX_BIN_DIR" => sandboxed_bin,
      }
    end

    def self.deactivate!
      Rubies.emit_vars!(deactivate)
    end

    def self.deactivate
      ruby_info = RubyInfo.from_whichever_ruby_is_in_the_path
      env = Environment.from_system_environment
      restored_path = Rubies.remove_from_PATH(env.current_path,
                                              [env.activated_ruby_bin,
                                               env.activated_sandbox_bin])
      {
        "PATH" => restored_path,
        "GEM_HOME" => nil,
        "GEM_PATH" => nil,
        "RUBIES_ACTIVATED_RUBY_BIN_DIR" => nil,
        "RUBIES_ACTIVATED_SANDBOX_BIN_DIR" => nil,
      }
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
      super(*self.class.members.map { |member| params.fetch(member) })
    end
  end

  class Environment < StrictStruct.new(:current_path,
                                       :current_gem_home,
                                       :current_gem_path,
                                       :activated_ruby_bin,
                                       :activated_sandbox_bin)

    def self.from_system_environment
      current_path = ENV.fetch("PATH")
      current_gem_home = ENV.fetch("GEM_HOME") { nil }
      current_gem_path = ENV.fetch("GEM_PATH") { nil }

      activated_ruby_bin = ENV.fetch("RUBIES_ACTIVATED_RUBY_BIN_DIR") { nil }
      activated_sandbox_bin = ENV.fetch("RUBIES_ACTIVATED_SANDBOX_BIN_DIR") { nil }

      new(:current_path => current_path,
          :current_gem_home => current_gem_home,
          :current_gem_path => current_gem_path,
          :activated_ruby_bin => activated_ruby_bin,
          :activated_sandbox_bin => activated_sandbox_bin)
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

  def self.remove_from_PATH(path_variable, dirs_to_remove)
    (path_variable.split(/:/) - dirs_to_remove).join(":")
  end

  def self.emit_vars!(vars)
    sorted_vars = vars.to_a.sort
    shell_code = sorted_vars.map do |k, v|
      if v.nil?
        %{unset #{k}}
      else
        %{export #{k}="#{v}"}
      end
    end.join("\n")
    puts shell_code
  end
end

if __FILE__ == $0
  case ARGV.fetch(0)
  when 'ruby-info' then Rubies::Commands.ruby_info
  when 'activate'
    ruby_name = ARGV.fetch(1)
    sandbox = ARGV.fetch(2)
    ruby_bin = File.expand_path("~/.rubies/#{ruby_name}/bin")
    Rubies::Commands.activate!(Rubies::Environment.from_system_environment,
                               Rubies::RubyInfo.from_bin_dir(ruby_bin),
                               ruby_name,
                               sandbox)
  when 'deactivate' then Rubies::Commands.deactivate!
  else raise ArgumentError.new("No subcommand given")
  end
end
