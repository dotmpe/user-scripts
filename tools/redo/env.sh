export log_key=redo:default.do[$$]
export verbosity="${verbosity:=${v:-4}}"
$LOG info ":redo-env" "Starting..." "v=$verbosity:tools/redo/env.sh"

true "${CWD:="${REDO_STARTDIR:?}"}"
true "${SUITE:="Main"}"
true "${BUILD_ENV:=defaults redo--}"
true "${PROJECT_CACHE:=".meta/cache"}"
true "${BUILD_RULES_BUILD:="${PROJECT_CACHE:?}/components.list"}"

true "${redo_opts:="-j4"}"

# XXX: for part:.meta/cache/components.list
BUILD_ENV_FUN=build_copy_changed


# Add current file to deps
redo-ifchange "${CWD:?}/tools/redo/env.sh" &&

true "${REDO_ENV_CACHE:="${PROJECT_CACHE:=".meta/cache"}/redo-env.sh"}"

# Built-in recipe for redo profile
test "${REDO_TARGET:-}" = "$REDO_ENV_CACHE" && {

  $LOG info ":redo-env" "Building cache..." "tools/redo/env.sh"
  build_env_default || return

  # Load additional local build-env parameters
  true "${ENV_BUILD_ENV:=$( sh_path=$CWD default_do_lookup \
      .build-env.sh \
      .meta/build-env.sh \
      tools/redo/build-env.sh )}"
  test -z "${ENV_BUILD_ENV:-}" || {
    redo-ifchange "$ENV_BUILD_ENV" || return
    . "$ENV_BUILD_ENV" || return
  }

  quiet=true build_env
  exit

} || {

  # For every other target, source the built profile and continue.
  redo-ifchange "$REDO_ENV_CACHE" || return
  $LOG debug ":redo-env" "Sourcing cache..." "tools/redo/env.sh"
  source "$REDO_ENV_CACHE"
}

$LOG "info" "" "Started redo env" "tools/redo/env.sh"
# Id: U-s
