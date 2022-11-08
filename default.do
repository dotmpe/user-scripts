#!/usr/bin/env bash

# The main project redo script controls project lifecycle and workflows.

# Created: 2018-11-14

default_do_env () # ~ # Prepare shell profile with build-target handler
{
  CWD=${REDO_STARTDIR:?}
  true "${ENV:="dev"}"
  true "${APP:="User-Scripts/0.0.2-dev"}"
  true "${ENV_BUILD:="tools/redo/env.sh"}"

  # Use ENV-BUILD as-is when given, or fall-back to default built-in method.
  test -e "$ENV_BUILD" && {
    . "$ENV_BUILD" || return
  } || {
    default_do_env_default
  }
}

default_do_env_default () # ~ # Default method to prepare redo shell profile
{
  true "${BUILD_ENV_CACHE:="${PROJECT_CACHE:=".meta/cache"}/redo-env.sh"}"

  # Built-in recipe for redo profile
  test "${REDO_TARGET:?}" = "$BUILD_ENV_CACHE" && {

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

    # Finally run some steps to generate the profile
    quiet=true build_env
    exit

  } || {

    # For every other target, source the built profile and continue.
    $LOG debug ":redo-env" "Sourcing cache..." "tools/redo/env.sh"
    redo-ifchange "$BUILD_ENV_CACHE" &&
    source "$BUILD_ENV_CACHE"
  }
}
# Export: build-target-env-default

build_env_default ()
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
# Export: build-env-default

default_do_lookup () # ~ <Paths...> # Lookup paths at PATH.
# Regular source or command do not look up paths, only local (base) names.
{
  local n e bd found sh_path=${sh_path:-} sh_path_var=${sh_path_var:-PATH}

  test -n "$sh_path" || {
    sh_path=${!sh_path_var:?}
  }

  for n in "${@:?}"
  do
    found=false
    for bd in $(echo "$sh_path" | tr ':' '\n')
    do
      for e in ${sh_exts:-""}
      do
        test -e "$bd/$n$e" || continue
        echo "$bd/$n$e"
        found=true
        break 2
      done
    done
    ${found} && {
      ${any:-false} && {
        ${first_only:-true} && return || continue
      }
    } || {
      ${any:-false} && continue || return
    }
  done
  ${found}
}
# Copy: sh-lookup

sh_mode ()
{
  test $# -eq 0 && {
    # XXX: sh-mode summary
    echo "$0: sh-mode: $-" >&2
    trap >&2
  } || {
    while test $# -gt 0
    do
      case "${1:?}" in
          ( build )
                set -CET &&
                trap "build_error_handler" ERR
              ;;
          ( dev )
                set -hET &&
                shopt -s extdebug
              ;;
          ( strict ) set -euo pipefail ;;
          ( * ) stderr_ "! $0: sh-mode: Unknown mode '$1'" 1 || return ;;
      esac
      shift
    done
  }
}
# Copy: sh-mode

build_error_handler ()
{
  stderr_ "! $0: Error in recipe for '${BUILD_TARGET:?}': E$?" $?
  exit $?
}

default_do_main ()
{
  # Get build-environment. Using `build- env` this is reduced to a single
  # argument line, a default script is included here in case no static
  # customized redo profile (ENV_BUILD) is needed or available for this
  # project. In that case $ENV_BUILD is generated from the output of the
  # equivalent function of the command line `build -env`, TODO: and the prerequisits
  # are set to the BUILD_ENV_SRC (and BUILD_ENV_CACHES?) value.

  # XXX: This implies a target/recipe for every of those sources that is a cache,
  # ENV_BUILD *must* handle those targets if they are *required* to run anything
  # else.
  # build- boot

  # The env profile for the build- env command itself is normally just the
  # build.lib.sh source. To add more handlers or other functions the static
  # ENV_BUILD_ENV file can be used.
  # The generated profile # can be used to perform target lookups without
  # having to source any other utilties on each invocation.
  # If the profile exports its dependencies, sub-processes might not need to
  # do any env preparation.

  # TODO: establish some idiom for the above.
  # Any complex build requiring lots of shell processing for each target will
  # quickly increase in run-time. This aims to take away a lot, but it needs
  # some standardized programs to put in place.
  # May be see to what degree large exported profiles can affect performance.
  # But in general profile should be relatively small, just complete enough
  # to capture generic project/build metadata and to do target lookup at least.

  BUILD_TARGET=${1:?}
  BUILD_TARGET_BASE=$2
  BUILD_TARGET_TMP=$3

  sh_mode dev strict build || return

  # Perform a standard ENV_BUILD build (with ENV_BUILD_ENV) if needed, and
  # source profile.
  default_do_env || return

  # Add current file to deps
  redo-ifchange "${CWD:?}/default.do" || return

  # Its possible to keep short build sequences in this file (below in the
  # case/easc). But to prevent unnecessary rebuilds after changing any other
  # default.do part we want them elsewhere where we can better control their
  # dependencies, preferably as precise as possible.
  case "${1:?}" in

    # 'all' is the only special redo-builtin (it does not show up in
    # redo-{targets,sources}), everything else are proper targets. Anything
    # seems to be accepted, '-' prefixed arguments are parsed as redo options
    # but after '--' we can pass targets that start with '-' as well.

    -env )     build-always && build_ env-sh >&2  ;;
    -info )    build-always && build_ info >&2 ;;
    -ood )     build-always && build-ood >&2 ;;
    -sources ) build-always && build-sources >&2 ;;
    -targets ) build-always && build-targets >&2 ;;
    "??"* )
        BUILD_TARGET=${BUILD_TARGET:2}
        BUILD_TARGET_BASE=${BUILD_TARGET_BASE:2}
        BUILD_TARGET_TMP=${BUILD_TARGET_TMP:2}
        build-always && build_ which "${BUILD_TARGET:?}" >&2 ;;
    "?"* )
        BUILD_TARGET=${BUILD_TARGET:1}
        BUILD_TARGET_BASE=${BUILD_TARGET_BASE:1}
        BUILD_TARGET_TMP=${BUILD_TARGET_TMP:1}
        build-always && build_ for-target "${BUILD_TARGET:?}" >&2 ;;

    ${HELP_TARGET:-help}|-help )    build-always
        echo "Usage: ${BUILD_TOOL-(BUILD_TOOL unset)} [${build_main_targets// /|}]" >&2
        echo "Default target (all): ${build_all_targets-(unset)}" >&2
        echo "Version: ${APP-(APP unset)}" >&2
      ;;

    # Default build target
    all|@all|:all )     build-always && build $build_all_targets
      ;;


    .build/tests/*.tap ) default_do_include \
          "tools/redo/parts/_build_tests_*.tap.do" "$@"
      ;;

    src/md/man/User-Script:*-overview.md ) default_do_include \
          "tools/redo/parts/src_man_man7_User-Script:*-overview.md.do" "$@"
      ;;

    src/man/man7/User-Script:*.7 ) default_do_include \
          "tools/redo/parts/src_man_man7_User-Script:*.7.do" "$@"
      ;;

    src/man/man*/*.* ) default_do_include \
          "tools/redo/parts/src_man_man*_*.*.do" "$@"
      ;;


    * )
        # Build target using alternative methods if possible.
        build_ target
      ;;

  esac
  # End build if handler has not exit already
  exit $?
}

test -z "${REDO_RUNID:-}" ||
    default_do_main "$@"

# Id: U-s:default.do                                               ex:ft=bash:
