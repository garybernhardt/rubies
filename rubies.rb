#!/usr/bin/env ruby
require 'rubygems'

class SystemState < Struct.new(:ruby_engine,
                               :ruby_version,
                               :gem_path,
                               :current_path,
                               :current_gem_home,
                               :current_gem_path,
                               :activated_ruby_bin,
                               :activated_sandbox_bin)
  DEFAULT_BIN_PATH = Object.new

  def initialize(ruby_bin_path=DEFAULT_BIN_PATH)
    # Get Ruby info
    ruby_engine, ruby_version, gem_path = get_ruby_info(ruby_bin_path)

    # Get current configuration
    current_path = ENV.fetch("PATH")
    current_gem_home = ENV.fetch("GEM_HOME") { nil }
    current_gem_path = ENV.fetch("GEM_PATH") { nil }

    # Get activated configuration
    activated_ruby_bin = ENV.fetch("RUBIES_ACTIVATED_RUBY_BIN_PATH") { nil }
    activated_sandbox_bin = ENV.fetch("RUBIES_ACTIVATED_SANDBOX_BIN_PATH") { nil }

    super(ruby_engine, ruby_version, gem_path, current_path, current_gem_home,
          current_gem_path, activated_ruby_bin, activated_sandbox_bin)
  end

  def get_ruby_info(ruby_bin_path)
    ruby_binary = if ruby_bin_path == DEFAULT_BIN_PATH
                    "ruby"
                  else
                    "#{ruby_bin_path}/ruby"
                  end

    ruby_info_string = `#{ruby_binary} #{File.expand_path($0)} ruby-info`
    unless $?.success?
      raise RuntimeError.new("Failed to get Ruby info; this is a bug!") 
    end

    ruby_info = ruby_info_string.split(/\n/)
    unless ruby_info.length == 3
      raise RuntimeError.new("Ruby info had wrong length; this is a bug!")
    end

    ruby_info
  end
end

def ruby_info
  ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
  ruby_version = RUBY_VERSION
  gem_path = Gem.path.join(':')

  puts [ruby_engine, ruby_version, gem_path].join("\n")
end

def activate(ruby_name, sandbox)
  ruby_bin = File.expand_path("~/.rubies/#{ruby_name}/bin")

  state = SystemState.new(ruby_bin)

  sandbox = File.expand_path(sandbox)
  sandboxed_gems = "#{sandbox}/.gem/#{state.ruby_engine}/#{state.ruby_version}"
  sandboxed_bin = "#{sandboxed_gems}/bin"

  current_path = remove_from_PATH(state.current_path,
                                  [state.activated_ruby_bin,
                                   state.activated_sandbox_bin])

  vars = {
    "PATH" => "#{sandboxed_bin}:#{ruby_bin}:#{state.current_path}",
    "GEM_HOME" => "#{sandboxed_gems}",
    "GEM_PATH" => "#{sandboxed_gems}:#{state.gem_path}",
    "RUBIES_ACTIVATED_RUBY_BIN_PATH" => ruby_bin,
    "RUBIES_ACTIVATED_SANDBOX_BIN_PATH" => sandboxed_bin,
  }
  emit_vars(vars)
end

def deactivate
  state = SystemState.new
  restored_path = remove_from_PATH(state.current_path,
                                   [state.activated_ruby_bin,
                                    state.activated_sandbox_bin])
  vars = {
    "PATH" => restored_path,
    "GEM_HOME" => nil,
    "GEM_PATH" => nil,
    "RUBIES_ACTIVATED_RUBY_BIN_PATH" => nil,
    "RUBIES_ACTIVATED_SANDBOX_BIN_PATH" => nil,
  }
  emit_vars(vars)
end

def remove_from_PATH(path_variable, paths_to_remove)
  (path_variable.split(/:/) - paths_to_remove).join(":")
end

def emit_vars(vars)
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

case ARGV.fetch(0)
when 'ruby-info' then ruby_info
when 'activate' then activate(ARGV.fetch(1), ARGV.fetch(2))
when 'deactivate' then deactivate
else raise ArgumentError.new("No subcommand given")
end
