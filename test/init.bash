#!/bin/bash


# Helpers for BATS project test env.

# Set env and other per-specfile init
test_env_init()
{
  test -n "$base" || return 12
  test -n "$uname" || uname=$(uname)
  test -n "$scriptpath" || scriptpath=$(pwd -P)

  # XXX: relative path to templates/fixtures?
  SHT_PWD="$( cd $BATS_CWD && realpath $BATS_TEST_DIRNAME )"
  test -n "$VND_SRC_PREFIX" || VND_SRC_PREFIX=/srv/src-local
  test -n "$VND_GH_SRC" || VND_GH_SRC=$VND_SRC_PREFIX/github.com
  hostname_init
}

hostname_init()
{
  hostnameid="$(hostname -s | tr 'A-Z.-' 'a-z__')"
}

init()
{
  test_env_init || return

  __load_mode=load-ext . $scriptpath/tools/sh/init.sh
  test "$1" = "0" || {
    test -n "$1" || set -- os sys str std
    lib_load "$@"
  }

  # Detect when base is exec
  test -x $PWD/$base && {
    bin=$base
  } || {
    test -x "$(which $base)" &&
        bin=$(which $base) || lib=$(basename $base .lib)
  }

  load $scriptpath/test/helper-extra.bash
  load $scriptpath/test/helper-stdtest.bash
#  load assert # XXX: conflicts, load overrides 'fail'

  export ENV_NAME=testing
}
