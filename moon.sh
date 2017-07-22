#!/bin/bash
###############################################################################
# Rakudo Moon
#
# Build's a bleeding edge version of Rakudo Perl 6 on the MoarVM backend,
# with the Zef package manager.
#
# Just call it from the folder you want to build Perl 6 into (called $P6DIR)
#
# In order to use the binaries, you should make sure that:
#
#  $P6DIR/rakudo/install/bin
#  $P6DIR/rakudo/install/share/perl6/site/bin
#  $P6DIR/rakudo/install/languages/perl6/site/bin
#
# are added to your PATH in your shell profile.
#
# NOTE: This is only tested on Linux, your mileage may vary.
#
###############################################################################

## The locations of our desired projects.
RAKUDO_GIT="git://github.com/rakudo/rakudo.git"
ZEF_GIT="git://github.com/ugexe/zef.git"

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
  add_path "$P6DIR/rakudo/install/share/perl6/site/bin"
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

## Get zef if we don't have it already.
need_zef() {
  NEED_PULL=1
  if [ ! -d "zef" ]; then 
    git clone $ZEF_GIT
    NEED_PULL=0
  fi
  return $NEED_PULL
}

## Bootstrap zef
bootstrap_zef() {
  NEED_PULL=`need_zef`
  pushd zef
  [ "$NEED_PULL" = "1" ] && git pull
  perl6 -Ilib bin/zef install .
  popd
}

show_help() {
  cat <<EOF
Rakudo Moon
-------------
usage: '$0' <action>

Actions:

  rakudo       Build/rebuild Rakudo.
  zef          Build/rebuild Zef.


EOF
  exit
}

## Select what to build.
case "$1" in
  rakudo)
    build_rakudo
  ;;
  zef)
    add_paths
    bootstrap_zef
  ;;
  *)
    show_help
  ;;
esac

echo "Build complete."

