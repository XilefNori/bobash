#!/usr/bin/env bash

# http://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/

# Install Homebrew

# First, visit Homebrew homepage and follow the installation instructions to install Homebrew.

# Shortcut: install the latest XCode and then run the following command to install:
# ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

# Then add the following line to your .bashrc or .zshrc:
# export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"

brew install coreutils

# Then you may probably want to install the following ones
# For some of the packages, you need to run brew tap homebrew/dupes first, but only once for your system
# brew tap homebrew/dupes

brew install binutils
brew install diffutils
brew install gawk
brew install gnutls
brew install findutils
brew install gnu-indent
brew install ed
brew install gnu-sed
brew install gnu-tar
brew install gnu-which
brew install gnutls
brew install grep
brew install wdiff
brew install gzip
brew install screen
brew install watch
brew install wget

# GNU Coreutils contains the most essential UNIX commands, such as ls, cat.
# The --default-names option will prevent Homebrew from prepending gs to the newly installed commands, thus we could use these commands as default ones over the ones shipped by OS X.

brew install bash
brew install gpatch
brew install m4
brew install make

# As a complementary set of packages, the following ones are not from GNU, but you can install and use a newer version instead of the version shipped by OS X:

brew install file-formula
brew install git
brew install less
brew install openssh
# brew install perl518   # must run "brew tap homebrew/versions" first!
# brew install python --with-brewed-openssl
brew install rsync
brew install unzip
# brew install vim --override-system-vi

# You may also want to add $HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman to the MANPATH environmental variable, where $HOMEBREW_PREFIX is the prefix of Homebrew, which is /usr/local by default. (Thanks Matthew Walker!) Alternatively, there is also a one-line setup which you could put in your shell configuration files here by quickshiftin.

