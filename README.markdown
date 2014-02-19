# Rubies

This is a prototype of a Ruby version/gemset manager written in Ruby. It may
not become a real, maintained project. DO NOT DEPEND ON IT FOR ANYTHING
IMPORTANT.

The core is rubies.rb, which doesn't change your environment; it just emits the
shell commands to activate or deactivate the Ruby version and gemset you give
it.

### Activating

```
eval `rubies.rb activate 2.1.0 .`
```

will activate Ruby 2.1.0 (it assumes it's in ~/.rubies/ruby-2.1.0), and will
set ./gems as the GEM_HOME and GEM_PATH (your current directory becomes the
"gemset").

Rubies currently has no mechanism for doing that automatically; right now, it's
just a primitive for constructing the environment, which is the hard part of
the logic, but not the hard part of the integration into current shells.

### Deactivating

```
eval `rubies.rb deactivate`
```

undoes whatever the activation did, so you should be back where you started.
(This is like `rvm use system`, etc.)

### How it works

Because all of the functionality is in a script that doesn't change the
environment, it's easy to see what it's doing. For example:

```
$ rubies.rb activate ruby-2.1.0 .
export GEM_HOME="/Users/grb/proj/rubies/.gem/ruby/2.1.0"
export GEM_PATH="/Users/grb/proj/rubies/.gem/ruby/2.1.0:/Users/grb/.gem/ruby/2.1.0:/Users/grb/.rubies/ruby-2.1.0/lib/ruby/gems/2.1.0"
export PATH="/Users/grb/proj/rubies/.gem/ruby/2.1.0/bin:/Users/grb/.rubies/ruby-2.1.0/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/texbin"
export RUBIES_ACTIVATED_RUBY_BIN_DIR="/Users/grb/.rubies/ruby-2.1.0/bin"
export RUBIES_ACTIVATED_SANDBOX_BIN_DIR="/Users/grb/proj/rubies/.gem/ruby/2.1.0/bin"
```

```
$ rubies.rb deactivate
unset GEM_HOME
unset GEM_PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/X11/bin:/usr/texbin"
unset RUBIES_ACTIVATED_RUBY_BIN_DIR
unset RUBIES_ACTIVATED_SANDBOX_BIN_DIR
```

### Remaining work

To make this a real, working thing usable in place of rvm, rbenv, etc., it
needs:

* A shell script wrapper. This is easy, which is the whole idea behind making
it a bunch of Ruby code that spits out shell commands. For example,

```
function rubies() {
  local assignments
  assignments=$(rubies.rb $*)
  if [[ $? == 0 ]]; then
      eval "$assignments"
  fi
}
```

* Automatic detection of and switching based upon .ruby-version and the
presence of a .gems directory.
[chruby](https://github.com/postmodern/chruby/blob/master/share/chruby/auto.sh)
does this, but I really do not want to maintain a bunch of multilingual
bash/zsh shell script.

* Ability to activate just a Ruby, or just a gemset. This is a straightforward
extension of the current logic; easy.
