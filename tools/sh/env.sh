#!/usr/bin/env bash

# Shell env profile script

test -z "${sh_env_:-}" && sh_env_=1 || return 98 # Recursion


: "${DEBUG:=""}"
: "${BASH_ENV:=""}"
: "${CWD:="$PWD"}"

export scriptname=${scriptname:-"`basename "$0"`"}

## Indicate this file is loading/included into env
#: "${USER_ENV:="$PWD/tools/sh/env.sh"}"
#export USER_ENV
#
## XXX: sync with current user-script tooling; +user-scripts
#: "${script_env_init:="$PWD/tools/sh/parts/env-0.sh"}"
#. "$script_env_init"
#
#
## XXX: user-scripts tooling
#. "$script_util/parts/env-std.sh"
#. "$script_util/parts/env-src.sh"
#. "$script_util/parts/env-ucache.sh"
#. "$script_util/parts/env-test-bats.sh"
##. "$script_util/parts/env-test-feature.sh"
#. "$script_util/parts/env-basher.sh"
#. "$script_util/parts/env-logger-stderr-reinit.sh"
#. "$script_util/parts/env-github.sh"


test -n "${sh_util_:-}" || {

  . "${script_util:="$CWD/tools/sh"}/util.sh"
  . "${script_util}/parts/print-color.sh"
  print_yellow "sh:util" "Loaded"
}

test -z "$DEBUG" || print_yellow "" "Starting sh:env '$_' '$*' <$0>"

# Keep current shell settings and mute while preparing env, restore at the end
: "${shopts:="$-"}"

#test -n "$DEBUG" && {
#    set -x || true;
#}


# Static init to run sh-dev-script based on PWD

test $# -gt 0 || {
  test -e "sh-`dirname "$PWD"`" && {
      set -- "sh-`dirname "$PWD"`"
  }
}

# Customizable user script config
test -e tools/sh/user-env.sh && {
  . "${USER_ENV:="$CWD/tools/sh/user-env.sh"}" || return
  test -z "$DEBUG" ||
    print_green "" "Loaded sh:user:env, continue with sh:env"

} || {

  test -z "$DEBUG" ||
    print_yellow "" "No local sh:user:env, continue with sh:env"
  : "${SCRIPT_ENV:="$CWD/tools/sh/env.sh"}"
  : "${USER_ENV:="$SCRIPT_ENV"}"
}
export SCRIPT_ENV USER_ENV


: "${SCRIPT_SHELL:="$SHELL"}"


func_exists error || ci_bail "std.lib missing"
func_exists req_vars || error "sys.lib missing" 1

# FIXME: @Travis DEBUG
#req_vars scriptname uname verbosity userscript

#req_vars scriptname uname verbosity userscript LOG INIT_LOG CWD ||
#  echo FIXME:ERR:$?

set +o nounset # NOTE: apply nounset only during init
#lib_load projectenv


### Start of build job parameterisation

sh_isset SHELLCHECK_OPTS ||
    export SHELLCHECK_OPTS="-e SC2154 -e SC2046 -e SC2015 -e SC1090 -e SC2016 -e SC2209 -e SC2034 -e SC1117 -e SC2100 -e SC2221"

GIT_CHECKOUT="$(git log --pretty=oneline | head -n 1 | cut -f 1 -d ' ' || true)"

BRANCH_NAMES="$(echo $(git ls-remote origin | grep -F "$GIT_CHECKOUT" | sed 's/.*\/\([^/]*\)$/\1/g' | sort -u ))"


## Determine ENV

case "$ENV_NAME" in development|testing ) ;; *|dev?* )
      test -z "$DEBUG" ||
        echo "Warning: No env '$ENV_NAME', overriding to 'dev'" >&2
      export ENV_NAME=dev
    ;;
esac

test -n "$ENV_NAME" || {

  note "Branch Names: $BRANCH_NAMES"
  case "$BRANCH_NAMES" in

    # NOTE: Skip build on git-annex branches
    *annex* ) exit 0 ;;

    gh-pages ) ENV_NAME=jekyll ;;
    test* ) ENV_NAME=testing ;;
    dev* ) ENV_NAME=development ;;
    * ) ENV_NAME=development ;;

  esac
}


export GIT_DESCRIBE="$(git describe --always)"


## Per-env settings

case "$ENV_NAME" in

  * ) ;;
esac



## Defaults


### End of build job parameterisation



# Restore shell -x opt
case "$shopts" in
  *x* )
    case "$DEBUG" in
      [Ff]alse|0|off|'' )
        # undo verbosity by Jenkins, unless DEBUG is explicitly on
        set +x ;;
      * )
        echo "[$0] Shell debug on (DEBUG=$DEBUG)"
        set -x ;;
    esac
  ;;
esac

test -z "$DEBUG" || print_green "" "Finished sh:env"

# From: script-mpe/0.0.4-dev tools/sh/env.sh
