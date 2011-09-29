#!/bin/bash
###############################################################################
# moon -- Build various Rakudo Perl 6 components on Linux.
#
# Rakudo Moon is the younger, less stable sibling of Rakudo Star.
# It's not as bright or shiny, and is a fraction of the size.
# It contains a very minimal set of utilities and libraries--just enough
# to install more from the Perl 6 ecosystem.
#
# While Rakudo Star is well tested, and uses known versions of its
# components, Rakudo Moon is bleeding edge, and uses the latest revisions.
# If you're going to reach for the moon, don't be surprised when you find
# yourself suffocating in the dead vacuum of space.
#
# You will need several development libraries in order to compile certain
# portions. Below is a list with the Debian/Ubuntu package names listed:
#
#  ICU library:   libicu-dev
#  GNU ReadLine:  libreadline6-dev (or libreadline5-dev on older distros.)
#  Perl 5 libs:   libperl-dev (only needed for Blizkost.)
#
# Usage:
#
#  First off, pick a directory where you want to keep your Perl 6 stuff.
#  Put the moon.sh file into that directory.
#  Make sure that you have ~/.perl6/bin and $P6DIR/bin in your PATH!
#
#  Type: ./moon.sh <action> [option]
#
# Actions:
#
#   install   <dist>      Build and install a new dist.
#   update    <dist>      Updates an already installed dist.
#   clean     <dist>      Cleans an installed dist, sometimes needed.
#   reinstall <dist>      Wipes out an existing dist, and does install again.
#
#   <dist>                Use a dist name by itself, and if it is installed
#                         it will be upgraded, otherwise it will be installed.
#
#   refresh-modules       Wipes out your existing ~/.perl6 and ~/.panda folders
#                         and re-installs any libraries you had installed
#                         using panda.
# 
#   rebuild <list>        A list of folders containing Perl 6 projects.
#                         It goes into the folder and does:
#                           make clean
#                           ufo
#                           make install
#                         You must have 'ufo' installed, if it isn't found,
#                         it will be installed using 'panda'. If panda isn't
#                         installed, it will fail with an error message.
#
#   apt-get-deps          On Debian or Ubuntu, use "sudo apt-get" to install
#                         the dependencies listed above.
#
# Dists:
#
#   rakudo               Rakudo Perl 6, including Parrot and NQP.
#   panda                The Panda package manager (requires rakudo.)
#   ufo                  The ufo build tool (requires panda.)
#   blizkost             The Blizkost Perl 5 engine (requires rakudo.)
#   zavolaj              The NativeCall library (requires panda.)
#
#   default              Installs rakudo, panda and ufo.
#   all                  Installs all known dists.
#
###############################################################################

## P6DIR: The directory we are building in.
P6DIR=`pwd`

#### ( Helper Functions ) ####

## add_path: Adds a path if it exists, does not duplicate.
add_path() {
  if [ -d "$1" ]; then
    echo $PATH | grep -q "$1"
    [ $? -ne 0 ] && PATH="$1:$PATH"
    export PATH
  fi
}

## die: Exit with a message.
die() {
  echo "$@"
  exit 1
}

## install_dist: Installs a dist using git.
install_dist() {
  DIST=$1
  GIT=$2
  [ -d "$DIST" ] && die "Existing $DIST installation found."
  git clone $GIT $DIST
  pushd $DIST
  BUILD="build_$DIST"
  $BUILD
  popd
}

## update_dist: Updates a dist using git.
update_dist() {
  DIST=$1
  [ ! -d "$DIST" ] && die "No $DIST installation found."
  pushd $DIST
  git pull
  BUILD="build_$DIST"
  $BUILD
  popd
}

## reinstall_dist: Removes an existing install, and runs install_dist again.
reinstall_dist() {
  DIST=$1
  [ -d "$DIST" ] && rm -rf "$DIST"
  INSTDIST="install_$DIST"
  $INSTDIST
}

## auto_dist: Installs or updates depending on existence.
auto_dist() {
  DIST=$1
  if [ -d "$DIST" ]; then
    DOCMD="update_$DIST"
  else
    DOCMD="install_$DIST"
  fi
  $DOCMD
}

## need: Ensure a dist is installed, if it isn't, install it.
need() {
  DIST=$1
  if [ ! -d "$DIST" ]; then
    PREP="prep_$DIST"
    $PREP
    INSTDIST="install_$DIST"
    $INSTDIST
  fi
}

## Spit out a help message
show_help() {
	sed -n -e '22,66s/^#//gp' $0 | less
	exit 1
}

## Show a usage message
usage() {
	die "$1. Type '$0 help' for usage details."
}

#### ( Initialize ) ####

add_path "$P6DIR/bin"
add_path ~/.perl6/bin

#### ( Definitions ) ####

### Rakudo ###

RAKUDO_GIT="git://github.com/rakudo/rakudo.git"

prep_rakudo() {
  echo "--rakudo--"
}

build_rakudo() {
  perl Configure.pl --gen-parrot
  make && make install
}

install_rakudo() {
  install_dist rakudo $RAKUDO_GIT
  if [ ! -e "./bin" ]; then
    ln -sv ./rakudo/install/bin .
    add_path "$P6DIR/bin"
  fi
}

update_rakudo() {
  update_dist rakudo
}

clean_rakudo() {
  [ ! -d "rakudo" ] && return; ## Silently ignore it.
  pushd rakudo
  rm -rf install
  pushd parrot
  make realclean
  popd
  pushd nqp
  make realclean
  popd
  popd
  echo "Build files cleaned and old installation removed."
}

reinstall_rakudo() {
  reinstall_dist rakudo
}

### panda ###

PANDA_GIT="git://github.com/tadzik/panda.git"

prep_panda() {
  echo "--panda--"
  need rakudo
}

build_panda() {
  bash ./bootstrap.sh
}

install_panda() {
  install_dist panda $PANDA_GIT
}

update_panda() {
  update_dist panda
}

clean_panda() {
  echo "Nothing to clean in 'panda'. See 'refresh-modules' instead."
}

reinstall_panda() {
  reinstall_dist panda
}

### ufo ###

prep_ufo() {
  echo "--ufo--"
  need panda
}

install_ufo() {
  panda install ufo
}

update_ufo() {
  install_ufo
}

clean_ufo() {
  echo "Nothing to clean in 'ufo'."
}

reinstall_ufo() {
  install_ufo
}

### blizkost ###

BLIZKOST_GIT="git://github.com/jnthn/blizkost.git"

prep_blizkost() {
  echo "--blizkost--"
  need rakudo
}

build_blizkost() {
  perl Configure.pl --with-parrot-config=$P6DIR/bin/parrot_config
  make && make install
}

install_blizkost() {
  install_dist blizkost $BLIZKOST_GIT
}

update_blizkost() {
  update_dist blizkost
}

clean_blizkost() {
  pushd blizkost
  make realclean
  popd
}

reinstall_blizkost() {
  reinstall_dist blizkost
}

### zavolaj ###

prep_zavolaj() {
  echo "--zavolaj--"
  need panda
}

install_zavolaj() {
  panda install NativeCall
}

update_zavolaj() {
  install_ufo
}

clean_zavolaj() {
  echo "Nothing to clean in 'zavolaj'."
}

reinstall_ufo() {
  install_zavolaj
}

#### ( Utility Commands ) ####

refresh_modules() {
  timestamp=`date +%s`
  [ -e "~/.perl6" ] && mv -v ~/.perl6 ~/.perl6-$timestamp
  [ -e "~/.panda" ] && mv -v ~/.panda ~/.panda-$timestamp
  install_panda ## Reinstall panda, ensuring a proper bootstrap.
  if [ -e "~/.panda-$timestamp" ]; then
    for pkg in `grep -E 'installed$' ~/.panda-$timestamp/state | sed -e 's/ installed//g' | grep -v panda`; do
      panda install $pkg
    done
  fi
}

rebuild_list() {
  LIST=$1
  for dir in `cat $LIST`; do
    pushd $dir
    make clean
    ufo
    make install
    popd
  done
}

## This totally depends on being a recent version of Debian or Ubuntu.
apt_get_moon_deps() {
  sudo apt-get install libicu-dev libreadline6-dev libperl-dev
}

## call_function: Call a given function on a given dist.
call_function() {
  MYFUNC=$1
  MYDIST=$2
  if [ "$MYFUNC" == "auto" ]; then
    auto_dist $MYDIST
  else
    MYCALL="${MYFUNC}_${MYDIST}"
    $MYCALL
  fi
}

## The defaults
call_defaults() {
  MYFUNC=$1
  call_function $MYFUNC rakudo
  call_function $MYFUNC panda
  call_function $MYFUNC ufo
}

## Everything
call_everything() {
  MYFUNC=$1
  call_defaults $MYFUNC
  call_function $MYFUNC blizkost
  call_function $MYFUNC zavolaj
} 

#### ( Process the commands ) ####

[ $# -lt 1 ] && usage "Not enough parameters"

MYFUNC="$1"

case "$MYFUNC" in
  install|update|reinstall|clean)
    [ $# -lt 2 ] && usage "No dist specified"
    MYDIST="$2"
    case "$MYDIST" in
      rakudo|panda|ufo|blizkost|zavolaj)
        call_function $MYFUNC $MYDIST
      ;;
      default)
        call_default $MYFUNC
      ;;
      all)
        call_everything $MYFUNC
      ;;
      *)
        usage "Unknown dist"
      ;;
    esac
  ;;
  rakudo|panda|ufo|blizkost|zavolaj)
    call_function auto $MYFUNC
  ;;
  default)
    call_default auto
  ;;
  all)
    call_everything auto
  ;;
  refresh-modules)
    refresh_modules
  ;;
  rebuild)
    [ $# -lt 2 ] && usage "No list specified"
    MYLIST="$2"
    [ ! -f "$MYLIST" ] && die "No such file '$MYLIST'."
    rebuild_list $MYLIST
  ;;
  apt-get-deps)
    apt_get_moon_deps
  ;;
	help|--help)
		show_help
	;;
  *)
    usage "Unknown command"
  ;;
esac

