#!/usr/bin/env ruby
require 'rubygems'

class SystemState < Struct.new(:ruby_engine,
                               :ruby_version,
                               :gem_path,
                               :current_path,
                               :current_gem_home,
                               :current_gem_path,
                               :activated_sandbox_bin)
  def initialize
    # Get Ruby info
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
    ruby_version = RUBY_VERSION
    gem_path = Gem.path.join(':')

    # Get current configuration
    current_path = ENV.fetch("PATH")
    current_gem_home = ENV.fetch("GEM_HOME") { nil }
    current_gem_path = ENV.fetch("GEM_PATH") { nil }

    # Get activated configuration
    activated_sandbox_bin = ENV.fetch("RUBIES_ACTIVATED_SANDBOX_BIN_PATH") { nil }

    super(ruby_engine, ruby_version, gem_path, current_path, current_gem_home,
          current_gem_path, activated_sandbox_bin)
  end
end

def activate(sandbox)
  state = SystemState.new
  sandbox = File.expand_path(sandbox)
  sandboxed_gems = "#{sandbox}/.gem/#{state.ruby_engine}/#{state.ruby_version}"
  sandboxed_bin = "#{sandboxed_gems}/bin"

  vars = {
    "PATH" => "#{sandboxed_bin}:#{state.current_path}",
    "GEM_HOME" => "#{sandboxed_gems}",
    "GEM_PATH" => "#{sandboxed_gems}:#{state.gem_path}",
    "RUBIES_ACTIVATED_SANDBOX_BIN_PATH" => sandboxed_bin,
  }
  emit_vars(vars)
end

def deactivate
  state = SystemState.new
  restored_path = remove_from_PATH(state.current_path,
                                   state.activated_sandbox_bin)
  vars = {
    "PATH" => restored_path,
    "GEM_HOME" => nil,
    "GEM_PATH" => nil,
    "RUBIES_ACTIVATED_SANDBOX_BIN_PATH" => nil,
  }
  emit_vars(vars)
end

def remove_from_PATH(path_variable, path_to_remove)
  (path_variable.split(/:/) - [path_to_remove]).join(":")
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
when 'activate' then activate(ARGV.fetch(1))
when 'deactivate' then deactivate
else raise ArgumentError.new("No subcommand given")
end
