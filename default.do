#!/usr/bin/env bash

# The main project redo script controls project lifecycle and workflows.

# Created: 2018-11-14

default_do_env () # ~ # Prepare shell profile with build-target handler
{
  CWD=${REDO_STARTDIR:?}
  BUILD_TOOL=redo
  BUILD_ID=$REDO_RUNID
  BUILD_STARTDIR=$CWD
  BUILD_BASE=${REDO_BASE:?}
  BUILD_PWD="${CWD:${#BUILD_BASE}}"
  test -z "$BUILD_PWD" || BUILD_PWD=${BUILD_PWD:1}
  BUILD_SCRIPT=${BUILD_PWD}${BUILD_PWD:+/}default.do
  test -z "$BUILD_PWD" && BUILD_PATH=$CWD || BUILD_PATH=$CWD:$BUILD_BASE

  # Use ENV-BUILD as-is when given, or fall-back to default built-in method.
  #test -e "$ENV_BUILD" && {
  #  . "$ENV_BUILD" || return
  #} || {
  #  default_do_env_default || return
  #}

  # TODO: work on build-env/env-build in build.lib, keep copies of routines
  # there for now
  BUILD_PATH=$BUILD_PATH:$U_S

  source "${U_S:?Required +U-s profile for @dev}/src/sh/lib/build.lib.sh" &&
  build_ env-build || return

  true "${ENV:="@dev"}"
  true "${APP:="@User-Scripts/0.0.2-dev"}"
}

sh_fun ()
{
  test "$(type -t "$1")" = function
}

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
  local r=$? lastarg=$_
  #! sh_fun stderr_ ||
  #  stderr_ "! $0: Error in recipe for '${BUILD_TARGET:?}': E$r" 0
  $LOG error ":on-error" "In recipe for '${BUILD_TARGET:?}' ($lastarg)" "E$r"
  exit $r
}

# Log-like handler for main default.do routines
default_do_ () # ~ <1:Level-name> <2:Key> <3:Msg> <4:Ctx> <5:Stat>
{
  declare lk=${2:-}
  test -n "$lk" -a "${lk:0:1}" = '$' && {
    lk="${log_key:-REDO[$$]}${log_key:+}(::${lk:1})"
  } ||
    true "${lk:=${log_key:-REDO[$$]}${log_key:+}(::do-env)}"
  $LOG "${1:-notice}" "$lk" "${3:?}" "${4:-}" ${5:-}
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

  # XXX: Not making this configurable (yet), parts will first have to be build
  # build_ do-session shell-mode
  sh_mode dev strict build || return

  #build_ do-env ||
  #  default_do_ error \$do-env "Error getting %.do env" "E$?" $?

  # Perform a standard ENV_BUILD build (with ENV_BUILD_ENV) if needed, and
  # source profile.
  default_do_env ||
    default_do_ error \$~do-env "Error getting %.do env" "E$?" $?

  # Its possible to keep short build sequences in this file (below in the
  # case/easc). But to prevent unnecessary rebuilds after changing any other
  # default.do part we want these elsewhere where we can better control their
  # dependencies and effects.

  test ! -e "${BUILD_SELECT_SH:=./.build-select.sh}" && unset BUILD_SELECT_SH ||
    . "${BUILD_SELECT_SH:?}"

  case "${1:?}" in

    # 'all' is the only special redo-builtin (it does not show up in
    # redo-{targets,sources}), everything else are proper targets. Anything
    # seems to be accepted, '-' prefixed arguments are parsed as redo options
    # but after '--' we can pass targets that start with '-' as well.

    # Current informative, inline recipes. Each of these is (more or less)
    # equal to calling build-<...> (and none are actually builds).
    -env )          ${BUILD_TOOL:?}-always && build_ env-sh >&2  ;;
    -info )         ${BUILD_TOOL:?}-always && build_ info >&2 ;;
    -ood )          ${BUILD_TOOL:?}-always && build-ood >&2 ;;
    -sources )      ${BUILD_TOOL:?}-always && build-sources >&2 ;;
    -targets )      ${BUILD_TOOL:?}-always && build-targets >&2 ;;
    "?"*|-show )    ${BUILD_TOOL:?}-always && build_ show-recipe >&2 ;;
    "??"*|-which )  ${BUILD_TOOL:?}-always && build_ which-names >&2 ;;
    "???"*|-what )  ${BUILD_TOOL:?}-always && build_ what-parts >&2 ;;

    # These directly call functions are defined at the project level, but can
    # be inherited.
    # XXX: fix non-recursive env-require

    ${HELP_TARGET:-help}|-help|-h ) ${BUILD_TOOL:?}-always &&
        # env_require local-libs || return
        build__usage_help
      ;;

    # Default build target
    all|@all|:all )
        # env_require local-libs || return
        build__all
      ;;

    * )
        # Build target using alternative methods if possible.
        #
        # env_require ${BUILD_TARGET_METHODS// /builder} || return
        # env_require ${BUILD_TARGET_HANDLERS:?} || return
        build_ target
      ;;

  esac

  # End build if handler has not exit already
  exit $?
}

test -z "${REDO_RUNID:-}" ||
    default_do_main "$@"

# Id: U-s:default.do                                               ex:ft=bash:
