#!/bin/ash

: "${hostname:="`hostname -s`"}"
: "${SCRIPTPATH:=""}"

: "${sh_src_base:="/src/sh/lib"}"
: "${sh_util_base:="/tools/sh"}"

: "${U_S:="$CWD"}"
: "${scriptpath:="$U_S$sh_src_base"}"

test -n "${script_env:-}" || {
  test -e "$PWD$sh_util_base/user-env.sh" &&
    script_env=$PWD$sh_util_base/user-env.sh ||
    script_env=$U_S$sh_util_base/user-env.sh
}

# Locate ztombol helpers and other stuff from github
: "${VND_GH_SRC:="/srv/src-local/github.com"}"
: "${VND_SRC_PREFIX:="$VND_GH_SRC"}"
