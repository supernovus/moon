#!/bin/bash
###############################################################################
# Rakudo Moon
#
# Build's a bleeding edge version of Rakudo Perl 6 on the MoarVM backend,
# and the Panda module installer. 
#
# Just call it from the folder you want to build Perl 6 into (called $P6DIR)
#
# In order to use Rakudo and Panda, you should make sure that:
#
#  $P6DIR/rakudo/install/bin
#  $P6DIR/rakudo/install/languages/perl6/site/bin
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

## Ensure the proper paths are in place.
add_paths() {
  add_path "$P6DIR/rakudo/install/bin"
  add_path "$P6DIR/rakudo/install/languages/perl6/site/bin"
}

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

  perl Configure.pl --gen-moar --backends=moar
  make && make install

  popd
}

## Get panda if we don't have it already.
need_panda() {
  NEED_PULL=1
  if [ ! -d "panda" ]; then
    git clone --recursive $PANDA_GIT panda
    NEED_PULL=0
  fi
  return $NEED_PULL
}

## Use the 'bootstrap' script on panda.
bootstrap_panda() {
  NEED_PULL=`need_panda`
  pushd panda
  [ "$NEED_PULL" = "1" ] && git pull
  ./bootstrap.pl
  popd
}

## Use the 'rebootstrap' script on panda.
rebootstrap_panda() {
  NEED_PULL=`need_panda`
  pushd panda
  [ "$NEED_PULL" = "1" ] && git pull
  ./rebootstrap.pl
  popd
}

show_help() {
  cat <<EOF
Rakudo Moon
-------------
usage: '$0' <action>

Actions:

  rakudo       Build/rebuild Rakudo.
  panda        Use bootstrap on Panda.
  repanda      Use rebootstrap on Panda.
  all          Build Rakudo and bootstrap Panda.
  reall        Same as all, but rebootstrap Panda.

EOF
  exit
}

## Select what to build.
case "$1" in
  rakudo)
    build_rakudo
  ;;
  panda)
    bootstrap_panda
  ;;
  repanda)
    rebootstrap_panda
  ;;
  all)
    build_rakudo
    add_paths
    bootstrap_panda
  ;;
  reall)
    build_rakudo
    add_paths
    rebootstrap_panda
  ;;
  *)
    show_help
  ;;
esac

echo "Build complete."

