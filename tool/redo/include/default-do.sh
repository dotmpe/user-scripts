# The main project redo script controls project lifecycle and workflows.

# Created: 2018-11-14

default_do_default_env ()
{
  :
#include <user-script.build.env.local.bash.h>
}

default_do_env () # ~ # Prepare shell profile with build-target handler
{
  [[ ${BUILD_ID-} ]] || {
    :
#include <user-script.build.xredo.runtime.bash>
  }

  # build_ do-env ||
  #  default_do_ error \$do-env "Error getting %%.do env" "E$?" $?

  if [[ ${ENV_TARGET:+set} || ${CONF_TARGET:+set} ]]; then
    if [[ ${ENV_TARGET:+set} && ${BUILD_TARGET} = "${ENV_TARGET-}" ]]
    then
      default_do_default_env || return
    elif [[ ${ENV_TARGET:+set} && ${BUILD_TARGET} != "${ENV_TARGET-}" &&
      ${CONF_TARGET:+set} && ${BUILD_TARGET} != "${CONF_TARGET-}" ]]
    then
      declare -I BUILD_ENV_SH
      if [[ ! -e "${BUILD_ENV_SH:=./.build-env.sh}" ]]
      then
        unset BUILD_ENV_SH
        redo-ifchange "$ENV_TARGET" &&
        . "$ENV_BASH" &&
        redo-ifchange "$BUILD_ENV_TARGET" &&
        . "$BUILD_ENV_BASH"
      else
        . "${BUILD_ENV_SH:?}" && exit ||
          sh_error E_BS -eq "${_E_next:-196}" || exit $E_BS
      fi
    fi
  fi
}

# Log-like handler for main default.do routines
# default_do_ () # ~ <1:Level-name> <2:Key> <3:Msg> <4:Ctx> <5:Stat>
# {
#   declare lk=${2:-}
#   test -n "$lk" -a "${lk:0:1}" = '$' && {
#     lk="${log_key:-REDO[$$]}${log_key:+}(::${lk:1})"
#   } ||
#     : "${lk:=${log_key:-REDO[$$]}${log_key:+}(::do-env)}"
#   $LOG "${1:-notice}" "$lk" "${3:?}" "${4:-}" ${5:-}
# }

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

  # Perform a standard ENV_BUILD build (with ENV_BUILD_ENV) if needed, and
  # source profile.
  default_do_env ||
    $LOG error :default.do "Loading env" "E$?" $? || return
    #default_do_ error \$~do-env "Error getting %%.do env" "E$?" $?

  # Its possible to keep short build sequences in this file (below in the
  # case/easc). But to prevent unnecessary rebuilds after changing any other
  # default.do part we want these elsewhere where we can better control their
  # dependencies and effects.

  declare -I BUILD_SELECT_SH
  if test ! -e "${BUILD_SELECT_SH:=./.build-select.sh}"
  then unset BUILD_SELECT_SH
  else
    . "${BUILD_SELECT_SH:?}" && exit ||
      sh_error E_BS -eq "${_E_next:-196}" || exit $E_BS
  fi

  lib_load envd ||
    failerr "E$? env failure" || return

  case "${1:?}" in

    # 'all' is the only special redo-builtin (it does not show up in
    # redo-{targets,sources}), everything else are proper targets. Anything
    # seems to be accepted, '-' prefixed arguments are parsed as redo options
    # but after '--' we can pass targets that start with '-' as well.

    # Current informative, inline recipes. Each of these is (more or less)
    # equal to calling build-<...> (and none are actually builds).
    -env* )         ${BUILD_TOOL:?}-always && build_ "${1:1}" >&2  ;;
    -info* )        ${BUILD_TOOL:?}-always && build_ "${1:1}" >&2 ;;
    -ood )          ${BUILD_TOOL:?}-always && build-ood >&2 ;;
    -sources )      ${BUILD_TOOL:?}-always && build-sources >&2 ;;
    -targets )      ${BUILD_TOOL:?}-always && build-targets >&2 ;;
    "???"*|-what )  ${BUILD_TOOL:?}-always && build_ what-parts >&2 ;;
    "??"*|-which )  ${BUILD_TOOL:?}-always && build_ which-names >&2 ;;
    "?"*|-show )    ${BUILD_TOOL:?}-always && build_ show-recipe >&2 ;;

    # These directly call functions are defined at the project level, but can
    # be inherited.
    # XXX: fix non-recursive env-require

    "${HELP_TARGET:-help}"|-help|-h ) ${BUILD_TOOL:?}-always &&
        envd_load build-lib || return
        build__usage_help
      ;;

    # Default build target
    all|@all|:all )
        envd_load build-lib || return
        build__all
      ;;

    * )
        # Build target using alternative methods if possible.
        #
        # env_require ${BUILD_TARGET_METHODS// /builder} || return
        # env_require ${BUILD_TARGET_HANDLERS:?} || return
        #stderr echo default.do build_ target
        us_debuglog "Kicking off target build"
        build_ target
      ;;

  esac

  # End build if handler has not exit already
  exit $?
}

test -z "${REDO_RUNID:-}" || {

  sh_mode strict build || return

  : "${US_DEBUG:=${DEBUG:=0}}"

  ! ((DEBUG)) ||
    $LOG info :default.do:main "Entering build script" \\
      "build-id:$REDO_RUNID $0:($#) $*"
  default_do_main "$@"
}

# Id: U-S::default-do                                             :ex:ft=bash:
