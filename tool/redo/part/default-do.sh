# The main project redo script controls project lifecycle and workflows.

# Created: 2018-11-14

#require fnmatch sh-fun sh-mode sh-error

default_do_env () # ~ # Prepare shell profile with build-target handler
{
  test -n "${BUILD_ID:-}" || {
    # . ${U_S:?}/tools/build/parts/build-static.sh
    CWD=${REDO_STARTDIR:?}
    BUILD_TOOL=redo
    BUILD_ID=$REDO_RUNID
    BUILD_STARTDIR=$CWD
    BUILD_BASE=${REDO_BASE:?}
    BUILD_PWD="${CWD:${#BUILD_BASE}}"
    test -z "$BUILD_PWD" || BUILD_PWD=${BUILD_PWD:1}
    BUILD_SCRIPT=${BUILD_PWD}${BUILD_PWD:+/}default.do
    test -z "$BUILD_PWD" && BUILD_PATH=$CWD || BUILD_PATH=$CWD:$BUILD_BASE
  }

  # Use external script during dev
  . ${U_S:?}/tools/build/parts/default-do-env@dev.sh || return

  true "${ENV:="@dev"}"
  true "${APP:="@User-Scripts/0.0.2-dev"}"
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
# XXX:

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

  #build_ do-env ||
  #  default_do_ error \$do-env "Error getting %%.do env" "E$?" $?

  # Perform a standard ENV_BUILD build (with ENV_BUILD_ENV) if needed, and
  # source profile.
  default_do_env ||
    $LOG error :default.do "Loading env" "E$?" $? || return
    #default_do_ error \$~do-env "Error getting %%.do env" "E$?" $?

  # Its possible to keep short build sequences in this file (below in the
  # case/easc). But to prevent unnecessary rebuilds after changing any other
  # default.do part we want these elsewhere where we can better control their
  # dependencies and effects.

  declare ERROR STATUS BUILD_SELECT_SH

  test ! -e "${BUILD_SELECT_SH:=./.build-select.sh}" &&
    unset BUILD_SELECT_SH || {
      . "${BUILD_SELECT_SH:?}" && STATUS=0 ||
        sh_error E_BS -eq "${_E_next:-196}" || return $E_BS
    }

  test 0 -eq ${STATUS:-1} || case "${1:?}" in

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
    "?"*|-show )    ${BUILD_TOOL:?}-always && build_ show-recipe >&2 ;;
    "??"*|-which )  ${BUILD_TOOL:?}-always && build_ which-names >&2 ;;
    "???"*|-what )  ${BUILD_TOOL:?}-always && build_ what-parts >&2 ;;

    # These directly call functions are defined at the project level, but can
    # be inherited.
    # XXX: fix non-recursive env-require

    ${HELP_TARGET:-help}|-help|-h ) ${BUILD_TOOL:?}-always &&
        env_require build-libs || return
        build__usage_help
      ;;

    # Default build target
    all|@all|:all )
        env_require build-libs || return
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

  ! "${US_DEBUG:-false}" || $LOG info :default.do:main "Entering build script" \
      "build-id:$REDO_RUNID $0:($#) $*"
  default_do_main "$@"
}

# Id: U-S::default-do
