#!/usr/bin/env ruby
require 'optparse'
require 'rubygems'

module Rubies
  def self.main
    subcommand, *args = Configuration.from_arguments(ARGV)
    case subcommand
    when 'ruby-info'
      Rubies::Commands.ruby_info!
    when 'activate'
      Rubies::Commands.activate!(*args)
    when 'deactivate'
      Rubies::Commands.deactivate!
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

  class Configuration
    def self.from_arguments(argv)
      parser = build_parser
      args = parse_args(parser, argv)
      enforce_subcommand_args(parser, args)
      args
    end

    def self.build_parser
      parser = OptionParser.new do |opts|
        opts.banner = dedent(<<-END)
        Usage: #{$PROGRAM_NAME} [options]
        END

        opts.on("-h", "--help", "Show this message") do |v|
          usage(0, parser)
        end

        opts.separator("")
        opts.separator("Available commands:")
        opts.separator("")
        opts.separator(dedent(<<-END))
        #{$PROGRAM_NAME} activate [ruby-name] [gem-path]
          Activates the named Ruby version and sets the gem path. The specified
          Ruby will be on $PATH. Gems will be installed to the specified gem
          path. Globally installed gems will still be visible.

        #{$PROGRAM_NAME} deactivate
          Undo whatever any previous activate did.
        END
      end
    end

    def self.parse_args(parser, argv)
      begin
        args = parser.parse(argv)
      rescue OptionParser::InvalidOption => e
        usage(1, e.to_s + "\n" + parser.to_s)
      end
    end

    def self.enforce_subcommand_args(parser, args)
      subcommand, *args = args
      if subcommand == nil
        usage(1, parser)
      elsif subcommand == "activate"
        if args.length != 2
          usage(1, parser, "wrong number of arguments for activate")
        end
      elsif subcommand == "deactivate"
        if args.length != 0
          usage(1, parser, "deactivate doesn't take any arguments")
        end
      elsif subcommand == "ruby-info"
        if args.length != 0
          usage(1, parser, "ruby-info doesn't take any arguments")
        end
      else
        usage(1, parser, "#{subcommand} is not a command")
      end
    end

    def self.usage(exit_status, usage_message, error_message=nil)
      message = [error_message, usage_message].compact.join("\n")
      $stderr.puts message
      raise SystemExit.new(exit_status)
    end

    def self.dedent(text)
      lines = text.split("\n")
      indentation = /^( *)/.match(lines.first).captures.first.length
      lines.map { |line| line[indentation..-1] }.join("\n")
    end
  end

  module Commands
    def self.activate!(ruby_name, sandbox)
      env = Rubies::Environment.from_system_environment(ENV)
      ruby_bin = File.expand_path("~/.rubies/#{ruby_name}/bin")
      ruby_info = Rubies::RubyInfo.from_bin_dir(ruby_bin)
      env = Rubies::Commands.activate(env, ruby_info, ruby_name, sandbox)
      puts env.to_shell_commands
    end

    def self.activate(env, ruby_info, ruby_name, sandbox)
      sandbox = File.expand_path(sandbox)
      sandboxed_gems = File.join(sandbox,
                                 ".gem",
                                 ruby_info.ruby_engine,
                                 ruby_info.ruby_version)
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
      env = Environment.from_system_environment(ENV)
      ruby_info = RubyInfo.from_whichever_ruby_is_in_the_path
      puts deactivate(env, ruby_info).to_shell_commands
    end

    def self.deactivate(env, ruby_info)
      restored_path = env.remove_dirs_from_path([env.activated_ruby_bin,
                                                 env.activated_sandbox_bin])
      Environment.new(
        :path => restored_path,
        :current_gem_home => nil,
        :current_gem_path => nil,
        :activated_ruby_bin => nil,
        :activated_sandbox_bin => nil)
    end

    def self.ruby_info!
      info = RubyInfo.from_this_ruby_process
      puts [info.ruby_engine, info.ruby_version, info.bin_dir, info.gem_path]
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

    def self.from_this_ruby_process
      new(:ruby_engine => defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby',
          :ruby_version => RUBY_VERSION,
          :bin_dir => RbConfig::CONFIG.fetch("bindir"),
          :gem_path => Gem.path.join(':'))
    end
  end
end

Rubies.main if __FILE__ == $0
