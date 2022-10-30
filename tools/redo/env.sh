export log_key=redo:default.do[$$]
export verbosity="${verbosity:=${v:-4}}"
$LOG info ":redo-env" "Starting..." "v=$verbosity:tools/redo/env.sh"

true "${CWD:="${REDO_BASE:-$PWD}"}"
true "${SUITE:="Main"}"
true "${BUILD_ENV:=defaults redo--}"
true "${PROJECT_CACHE:=".meta/cache"}"
true "${BUILD_RULES_BUILD:="${PROJECT_CACHE:?}/components.list"}"

true "${redo_opts:="-j4"}"

# XXX: for part:.meta/cache/components.list
BUILD_ENV_FUN=build_copy_changed


tools_redo_env_default ()
{
  local depsrc
  for depsrc in "${U_S:?}/src/sh/lib/build.lib.sh" "${CWD:?}/build-lib.sh"
  do
    test -e "$depsrc" || continue
    redo-ifchange "$depsrc" &&
    source "$depsrc" || return
  done
  build_lib_load
}

# Add current file to deps
redo-ifchange "${CWD:?}/tools/redo/env.sh" &&

true "${REDO_ENV_CACHE:="${PROJECT_CACHE:-".meta/cache"}/redo-env.sh"}"

test "${REDO_TARGET:?}" = "$REDO_ENV_CACHE" && {

  $LOG info ":redo-env" "Building cache..." "tools/redo/env.sh"
  true "${ENV_BUILD_ENV:="tools/redo/build-env.sh"}"

  # Allow to build build-env profile as well.
  test "${ENV_BUILD_BUILD_ENV:-0}" != "1" || {
    ${BUILD_TOOL:?}-ifchange "$ENV_BUILD_ENV" || return
  }

  test ! -e "$ENV_BUILD_ENV" || {
    . "$ENV_BUILD_ENV" || return
  }

  tools_redo_env_default &&
  quiet=true build_env
  exit

} || {

  $LOG debug ":redo-env" "Sourcing cache..." "tools/redo/env.sh"
  redo-ifchange "$REDO_ENV_CACHE" &&
  source "$REDO_ENV_CACHE"
}

$LOG debug ":redo-env" "Booting..." "tools/redo/env.sh"
BUILD_ACTION=env build_boot

$LOG "info" "" "Started redo env" "tools/redo/env.sh"
# Id: U-s
