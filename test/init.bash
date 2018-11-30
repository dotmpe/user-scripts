#!/bin/bash

# Helpers for BATS project test env.


# Set env and other per-specfile init
test_env_init()
{
  test -n "$base" || return 12
  test -n "$scriptname" &&
    scriptname=$scriptname:test:$base ||
    scriptname=test:$base
  test -n "$uname" || uname=$(uname)

  test -n "$scriptpath" || scriptpath=$(pwd -P)/src/sh/lib
  test -n "$script_util" || script_util=$(pwd -P)/tools/sh

  test -n "$testpath" || testpath=$(pwd -P)/test
  test -n "$default_lib" || default_lib="os sys str logger-std"


  test -n "$BATS_LIB_PATH" || {
    BATS_LIB_PATH=$BATS_CWD/test:$BATS_CWD/test/helper:$BATS_TEST_DIRNAME
  }
  test -n "$BATS_LIB_EXTS" || BATS_LIB_EXTS=bash\ sh
  test -n "$BATS_LIB_DEFAULT" || BATS_LIB_DEFAULT=load


  # XXX: relative path to templates/fixtures?
  SHT_PWD="$( cd $BATS_CWD && realpath $BATS_TEST_DIRNAME )"

  # Locate ztombol helpers and other stuff from github
  test -n "$VND_SRC_PREFIX" || VND_SRC_PREFIX=/srv/src-local
  test -n "$VND_GH_SRC" || VND_GH_SRC=$VND_SRC_PREFIX/github.com
  hostname_init
}

hostname_init()
{
  hostnameid="$(hostname -s | tr 'A-Z.-' 'a-z__')"
}

# XXX: temporary override for Bats load
#BATS_TEST_LIB=
#BATS_LIB_EXTS=bash\ sh
load() # ( PATH | NAME )
{
  while test $# -gt 0 
  do
    load_helper "$1" || return $?
    shift
  done
}

load_helper()
{
  test -e "$1" && {
    . "$1"
    return $?
  }
  for i in ${BATS_LIB_PATH//:/ }
  do
    test -d "$i/$1" && {

      for e in $BATS_LIB_EXTS
      do
        test -e "$i/$1/$BATS_LIB_DEFAULT.$e" && {
          . "$i/$1/$BATS_LIB_DEFAULT.$e"
          return $?
        }
      done

    } || {

      test -e "$i/$1" && {
        . "$i/$1"
        return $?
      }
      for e in $BATS_LIB_EXTS
      do
        test -e "$i/$1.$e" && {
          . "$i/$1.$e"
          return $?
        }
      done
    }
  done
  return 1
}

init()
{
  test_env_init || return

  # Detect when base is exec
  test -x $PWD/$base && {
    bin=$base
  } || {
    test -x "$(which $base)" && bin=$(which $base) || lib=$(basename $base .lib)
  }

  # Get lib-load, and optional libs/boot script/helper

  test -n "$2" && init_sh_boot="$2"
  test "$1" = "0" || { test -n "$init_sh_boot" || init_sh_boot="null"; }

# XXX scriptpath
  scriptpath=$PWD/src/sh/lib SCRIPTPATH=$PWD/src/sh/lib:$HOME/bin
  init_sh_libs="$1" . $script_util/init.sh

  test "$1" = "0" || {
    lib_load $default_lib
  }

  test "$2" = "0" || {
    load extra
    load stdtest
    #load assert # XXX: conflicts, load overrides 'fail'
  }

  export ENV_NAME=testing
}
