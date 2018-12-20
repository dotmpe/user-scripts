#!/bin/ash

: "${CWD:=$PWD}"


: "${script_env_init:=$CWD/tools/sh/parts/env.sh}"
. "$script_env_init"


: "${USER_ENV:=tools/sh/env.sh}"
export USER_ENV


export scriptname=${scriptname:-$(basename "$0")}

export uname=${uname:-$(uname -s)}


. $script_util/parts/env-std.sh
. $script_util/parts/env-src.sh
. $script_util/parts/env-test-bats.sh
. $script_util/parts/env-basher.sh
. $script_util/parts/env-logger.sh
. $script_util/parts/env-github.sh
# XXX: user-env?
#. $script_util/parts/env-scriptpath.sh
