#!/usr/bin/env bash

# The main project redo script controls project lifecycle and workflows.

# Created: 2018-11-14

default_do_env () # ~ # Prepare shell profile with build-target handler
{
  true "${ENV:="dev"}"
  true "${APP:="User-Scripts/0.1-alpha"}"
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
  true "${REDO_ENV_CACHE:="${PROJECT_CACHE:-".meta/cache"}/redo-env.sh"}"

  # Built-in recipe for redo profile
  test "${REDO_TARGET:?}" = "$REDO_ENV_CACHE" && {

    true "${ENV_BUILD_ENV:="tools/redo/build-env.sh"}"

    # Allow to build build-env profile as well.
    test "${ENV_BUILD_BUILD_ENV:-0}" != "1" || {
      build-ifchange "$ENV_BUILD_ENV" || return
    }

    test ! -e "$ENV_BUILD_ENV" || {
      . "$ENV_BUILD_ENV" || return
    }

    # Add current file to deps
    #redo-ifchange "${REDO_BASE:?}/tools/redo/env.sh" &&

    # Finally run some steps to generate the profile
    source "${U_S:?}/src/sh/lib/build.lib.sh" &&
    quiet=true build_env
    exit

  } || {

    # For every other target, source the built profile and continue.
    redo-ifchange "$REDO_ENV_CACHE" &&
    source "$REDO_ENV_CACHE"
  }
}

default_do_main ()
{
  # Add current file to deps
  redo-ifchange "${REDO_BASE:?}/default.do" || return

  # Get build-environment. Using `build- env` this is reduced to a single
  # argument line, and a default script is included here in case no static
  # redo profile (ENV_BUILD) is available for this project.

  # The env profile for the build- env command itself is normally just the
  # build.lib.sh source. To add more handlers or other functions the static
  # ENV_BUILD_ENV file is to be used.

  # This setup allows to be as lightweight as possible. The generated profile
  # used by this default.do recipe can use be used to perform target lookups
  # without having to source any other utilties on each invocation, greatly
  # speeding up simple targets. More complex targets can use the profile to
  # include other parts as required.

  # The trade-off is how much to include with the profile to allow for various
  # types of targets to run.
  # The downside of having to load anything, is that it has to load on each redo
  # invocation. Without having a pure shell script build-system there is no way
  # to get around that.
  # Any complex build requiring lots of shell processing for each target will
  # quickly increase in run-time.

  # Any way you look at it, it is best to keep the sourcing and other
  # shell processing as low as possible.

  BUILD_TARGET=$1
  BUILD_TARGET_BASE=$2
  BUILD_TARGET_TMP=$3

  # XXX: build.lib.sh is currently using nullglob shell option, to cannot
  # remove env bash line (even if /bin/sh points to bash) anywy. So enable
  # pipefail as well...
  set -euETo pipefail
  shopt -s extdebug
  # TODO: load/init sh debug libs

  # Perform a standard ENV_BUILD build (with ENV_BUILD_ENV) if needed, and
  # source profile.
  default_do_env || return

  #BUILD_ACTION=build build_boot || return

  # Its possible to keep short build sequences in this file (below in the
  # case/easc). But to prevent unnecessary rebuilds after changing any other
  # default.do part we want them elsewhere where we can better control their
  # dependencies, preferably as precise as possible.
  case "$1" in

    # 'all' is the only special redo-builtin (it does not show up in
    # redo-{targets,sources}), everything else are proper targets. Anything
    # seems to be accepted, '-' prefixed arguments are parsed as redo options
    # but after '--' we can pass targets that start with '-' as well.

    -env )     build-always && build_env_sh >&2  ;;
    -info )    build-always && build_info >&2 ;;
    -ood )     build-always && build-ood >&2 ;;
    -sources ) build-always && build-sources >&2 ;;
    -targets ) build-always && build-targets >&2 ;;
    # XXX: see also build-whichdo, build-log

    "??"* )
        BUILD_TARGET=${BUILD_TARGET:1}
        BUILD_TARGET_BASE=${BUILD_TARGET_BASE:1}
        BUILD_TARGET_TMP=${BUILD_TARGET_TMP:1}
        build_which "$BUILD_TARGET" >&2 ;;

    "?"* )
        BUILD_TARGET=${BUILD_TARGET:1}
        BUILD_TARGET_BASE=${BUILD_TARGET_BASE:1}
        BUILD_TARGET_TMP=${BUILD_TARGET_TMP:1}
        build_for_target >&2 ;;

    help|-help|:help )    build-always
              echo "Usage: $BUILD_TOOL [${build_main_targets// /|}]" >&2
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
        build_target
        exit
      ;;

  esac
}

test -z "${REDO_RUNID:-}" ||
    default_do_main "$@"

# Id: U-s:default.do                                               ex:ft=bash:
