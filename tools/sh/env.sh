#!/bin/ash

: "${BASH_ENV:=""}"
: "${CWD:="$PWD"}"


# Indicate this file is loading/included into env
: "${USER_ENV:="$PWD/tools/sh/env.sh"}"
export USER_ENV

# XXX: sync with current user-script tooling; +user-scripts
: "${script_env_init:="$PWD/tools/sh/parts/env-0.sh"}"
. "$script_env_init"


# XXX: user-scripts tooling
. "$script_util/parts/env-std.sh"
. "$script_util/parts/env-src.sh"
. "$script_util/parts/env-ucache.sh"
. "$script_util/parts/env-test-bats.sh"
#. "$script_util/parts/env-test-feature.sh"
. "$script_util/parts/env-basher.sh"
. "$script_util/parts/env-logger-stderr-reinit.sh"
. "$script_util/parts/env-github.sh"
# XXX: user-env?
#. "$script_util/parts/env-scriptpath.sh"
