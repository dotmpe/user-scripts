true "${UC_LOG_BASE:=redo:default.do[$$]}"
declare -x UC_LOG_BASE
export verbosity="${verbosity:=${v:-4}}"
$LOG info ":Tools:Redo:env" "Starting..." "v=$verbosity:U-s:tools/redo/env.sh"

true "${CWD:="${REDO_STARTDIR:?}"}"
true "${SUITE:="Main"}"
true "${BUILD_ENV:=build-rules build-lib rule-params redo-- defaults stderr_ argv}"
true "${PROJECT_CACHE:=".meta/cache"}"
true "${BUILD_RULES_BUILD:="${PROJECT_CACHE:?}/build-rules.list"}"
true "${BUILD_RULES:=".meta/stat/index/build-rules-us.list"}"

true "${redo_opts:="-j4"}"

# XXX: for part:.meta/cache/components.list
BUILD_ENV_FUN=build_copy_changed


# Add current file to deps
#redo-ifchange "${CWD:?}/tools/redo/env.sh" &&

true "${BUILD_ENV_CACHE:="${PROJECT_CACHE:=".meta/cache"}/redo-env.sh"}"

# Built-in recipe for redo profile
test "${BUILD_TARGET:?}" = "$BUILD_ENV_CACHE" && {

  $LOG info ":Tools:Redo:env" "Building cache..." "${BUILD_ENV_CACHE:?}"
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

  test "$BUILD_TARGET" != "$BUILD_RULES" -a \
      "$BUILD_TARGET" != "$BUILD_RULES_BUILD" -a \
      -e "$BUILD_ENV_CACHE" || {

    #build_env_targets_default &&
    build_env_default
    return
  }

  # For every other target, source the built profile and continue.
  redo-ifchange "$BUILD_ENV_CACHE" || return
  $LOG debug ":Tools:Redo:env" "Sourcing cache..." "${BUILD_ENV_CACHE:?}"
  source "$BUILD_ENV_CACHE"
}

$LOG "info" ":Tools:Redo:env" "Started redo env" "${BUILD_ENV_CACHE:?}"
# Id: U-s
