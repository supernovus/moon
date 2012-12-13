#!/bin/bash
###############################################################################
# Rakudo Moon
#
# Build's a bleeding edge version of Rakudo Perl 6 and the Panda module
# installer. This is a far more minimal version of the moon script.
# The old version had a lot of functionality that is no longer required.
#
# Just call it from the folder you want to build Perl 6 into (called $P6DIR)
#
# In order to use Rakudo and Panda, you should make sure that both:
#
#  $P6DIR/bin
#  ~/.perl6/bin
#
# are added to your PATH in your shell profile.
#
# NOTE: This is only tested on Linux, your mileage may vary.
#
###############################################################################

## The locations of our desired projects.
RAKUDO_GIT="git://github.com/rakudo/rakudo.git"
PANDA_GIT="git://github.com/tadzik/panda.git"

## Record our own path.
P6DIR=`pwd`

## Add a path with no duplication.
add_path() {
  if [ -d "$1" ]; then
    echo $PATH | grep -q "$1"
    [ $? -ne 0 ] && PATH="$1:$PATH"
    export PATH
  fi
}

## Set up our paths.
add_path "$P6DIR/bin"
add_path ~/.perl6/bin

## Build Rakudo.
build_rakudo() {
  echo "--- Building Rakudo Perl 6 ---"
  if [ -d "rakudo" ]; then
    pushd rakudo
    git pull
  else
    git clone $RAKUDO_GIT rakudo
    pushd rakudo
  fi

  perl Configure.pl --gen-parrot
  make && make install

  popd

  ## Link into our "bin" folder.
  if [ ! -e "bin" -a -e "./rakudo/install/bin" ]; then
    ln -sv ./rakudo/install/bin .
    add_path "$P6DIR/bin"
  fi
}

## Build Panda.
build_panda() {
  echo "--- Building Panda ---"
  if [ -d "panda" ]; then
    pushd panda
    git pull
    ./rebootstrap.pl
    popd
  else
    git clone $PANDA_GIT panda
    pushd panda
    ./bootstrap.pl
    popd
    add_path ~/.perl6/bin
  fi
}

## Select what to build.
## It is recommended that you build everything, every time.
## Selective builds lead to problems, so don't do it unless you know
## what you are doing.
case "$1" in
  rakudo)
    build_rakudo
  ;;
  panda)
    build_panda
  ;;
  *)
    build_rakudo
    build_panda
  ;;
esac

echo "Build complete."
