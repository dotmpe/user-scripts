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

  export LOG=$script_util/log.sh

  # XXX: relative path to templates/fixtures?
  SHT_PWD="$( cd $BATS_CWD && realpath $BATS_TEST_DIRNAME )"

  # Locate ztombol helpers and other stuff from github
  test -n "$VND_SRC_PREFIX" || return 100
  test -n "$VND_GH_SRC" || VND_GH_SRC=$VND_SRC_PREFIX/github.com
  hostname_init
}

hostname_init()
{
  hostnameid="$(hostname -s | tr 'A-Z.-' 'a-z__')"
}

# 1:Init 2:Load-Libs 3:Boot-Std 4:Boot-Script
init() # ( 0 | 1 1 1 1 )
{
  test_env_init || return

  # Detect when base is exec
  test -x $PWD/$base && {
    bin=$base
  } || {
    test -x "$(which $base)" && bin=$(which $base) || lib=$(basename $base .lib)
  }

  # Get lib-load, and optional libs/boot script/helper

  export ENV_NAME=testing

  test -n "$1" || set -- 1 "$1" "$3" "$4"
  test -n "$2" || set -- "$1" 1 "$3" "$4"
  test -n "$3" || set -- "$1" "$2" 1 "$4"
  test -n "$4" || set -- "$1" "$2" "$3" 1

  test "$1" != "0" || return 0

  init_sh_libs="$2"
  init_sh_boot="$3"

  test "$2" != "1" -o \( -n "$3" -a "$3" != "0" \) || init_sh_boot="null"
  test "$init_sh_boot" = "1" && {
    test "$3" = "0" || init_sh_boot='std test'
    test "$4" = "0" || init_sh_boot=$init_sh_boot' script'
  }

  load_init_bats

# FIXME: deal with sub-envs wanting to know about lib-envs exported by parent
# ie. something around ENV_NAME, ENV_STACK. Renamed ENV_SRC to LIB_SRC for now
# and dealing only with current env, testing lib-load and tools, user-scripts.
  LIB_SRC=
  . $script_util/init.sh || return

}


# XXX: temporary override for Bats load
load_old() {
  local name="$1"
  local filename

  if [[ "${name:0:1}" == '/' ]]; then
    filename="${name}"
  else
    filename="$BATS_TEST_DIRNAME/${name}.bash"
  fi

  if [[ ! -f "$filename" ]]; then
    printf 'bats: %s does not exist\n' "$filename" >&2
    exit 1
  fi

  source "${filename}"
}

# XXX: intial bits shouldn't they be in suite exec.
bats_autosetup_common_includes()
{
  : "${BATS_LIB_PATH_DEFAULTS:="test helper test/helper node_modules vendor"}"

  # Basher has a GitHub <user>/<package> checkout tree
  : "${BASHER_PACKAGES:=$HOME/.basher/cellar/packages}"
  test ! -d $BASHER_PACKAGES ||
    BATS_LIB_PATH_DEFAULTS="$BATS_LIB_PATH_DEFAULTS $BASHER_PACKAGES"

  test -e /src/ &&
    : "${VND_SRC_PREFIX:="/src"}" ||
    : "${VND_SRC_PREFIX:="$HOME/build"}"

  : "${VENDORS:="google.com github.com bitbucket.org"}"
  for vendor in $VENDORS
  do
    test -e $VND_SRC_PREFIX/$vendor || continue

    BATS_LIB_PATH_DEFAULTS="$BATS_LIB_PATH_DEFAULTS $VND_SRC_PREFIX/$vendor"
  done
}

bats_dynamic_include_path()
{
  # Require BATS_LIB_PATH_DEFAULTS, a list of partial relative and
  # absolute path names to initialze BATS_LIB_PATH with
  bats_autosetup_common_includes

  # Build up default path, start-to-end.
  BATS_LIB_PATH="$BATS_TEST_DIRNAME"

  # Add default helper or package locations, for relative paths
  # first those beside test script (BATS_TEST_DIRNAME) then BATS_CWD
  for path_default in $BATS_LIB_PATH_DEFAULTS
  do
    test "${path_default:0:1}" = '/' && {
      test -e "$path_default"  || continue

      BATS_LIB_PATH="$BATS_LIB_PATH:$path_default"
    } || {

      for bats_path in "$BATS_TEST_DIRNAME" "$BATS_CWD"
      do
        test -d "$bats_path/$path_default" || continue
        BATS_LIB_PATH="$BATS_LIB_PATH:$bats_path/$path_default"
      done
    }
  done
}

load_init_bats()
{
  test -n "$BATS_LIB_PATH" || bats_dynamic_include_path
  
  test -n "$BATS_LIB_EXTS" || BATS_LIB_EXTS=.bash\ .sh
  test -n "$BATS_VAR_EXTS" || BATS_VAR_EXTS=.txt\ .tab
  test -n "$BATS_LIB_DEFAULT" || BATS_LIB_DEFAULT=load
}

load() # ( PATH | NAME )
{
  test $# -gt 0 || return 1
  : "${lookup_exts:=${BATS_LIB_EXTS}}"
  while test $# -gt 0 
  do
    source $(bats_lib_lookup "$1" || return $? ) || return $?
    shift
  done
}

bats_lib_lookup()
{
  test $# -eq 1 || return 1
  : "${lookup_exts:=${BATS_VAR_EXTS}}"
  test "${1:0:1}" = '/' -a -e "$1" && {
    echo "$1"
    return
  }
  for i in ${BATS_LIB_PATH//:/ }
  do
    test -d "$i/$1" && {

      for e in $lookup_exts
      do
        test -e "$i/$1/$BATS_LIB_DEFAULT$e" && {
          echo "$i/$1/$BATS_LIB_DEFAULT$e"
          return
        }
      done

    }
    test -f "$i/$1" && {
      echo "$i/$1"
      return
    }
    for e in $lookup_exts
    do
      test -e "$i/$1$e" && {
        echo "$i/$1$e"
        return
      }
    done
  done
  return 1
}
