#!/bin/bash
###############################################################################
# Rakudo Moon
#
# Build's a bleeding edge version of Rakudo Perl 6 and the Panda module
# installer. Supports the Parrot, MoarVM and JVM backends of Rakudo, and
# offers an easy way to switch between them.
#
# Just call it from the folder you want to build Perl 6 into (called $P6DIR)
#
# In order to use Rakudo and Panda, you should make sure that both:
#
#  $P6DIR/rakudo/install/bin
#  $P6DIR/rakudo/install/lib/parrot/*/languages/perl6/site/bin
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
  add_path "$P6DIR/rakudo/install/lib/parrot/*/languages/perl6/site/bin"
}

## Switch the active "perl6" executable to one of the -p, -m, or -j versions.
use6() {
  P6BIN=$P6PATH/rakudo/install/bin/perl6
  if [ ! -f $P6BIN-$1 ]; then
    echo "invalid implementation";
    return;
  fi
  rm -vf $P6BIN
  ln -sv $P6BIN-$1 $P6BIN
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

  perl Configure.pl --gen-parrot --gen-moar --gen-nqp --backends=parrot,moar,jvm
  make && make install

  popd
}

## Get panda if we don't have it already.
need_panda() {
  NEED_PULL=1
  if [ ! -d "panda" ]; then
    git clone --recursive $PANDA_GIT panda
    git checkout moar-support ## remove this once merged into master.
    NEED_PULL=0
  fi
  return $NEED_PULL
}

## Use the 'bootstrap' script on panda.
bootstrap_panda() {
  NEED_PULL=`need_panda`
  pushd panda
  [ $NEED_PULL -eq 1 ] && git pull
  ./bootstrap.pl
  popd
}

## Use the 'rebootstrap' script on panda.
rebootstrap_panda() {
  NEED_PULL=`need_panda`
  pushd panda
  [ $NEED_PULL -eq 1 ] && git pull
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
  all          Build Rakudo and bootstrap panda for all backends.
  reall        Same as all, but rebootstrap panda for all backends.

  -p           Switch 'perl6' to Parrot backend (perl6-p).
  -m           Switch 'perl6' to MoarVM backend (perl6-m).
  -j           Switch 'perl6' to JVM backend    (perl6-j).

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
    use6 p
    boostrap_panda
    use6 m
    bootstrap_panda
    use6 j
    bootstrap_panda
  ;;
  reall)
    build_rakudo
    add_paths
    use6 p
    rebootstrap_panda
    use6 m
    rebootstrap_panda
    use6 j
    rebootstrap_panda
  ;;
  -p)
    use6 p
  ;;
  -m)
    use6 m
  ;;
  -j)
    use6 j
  ;;
  *)
    show_help
  ;;
esac

echo "Build complete."
