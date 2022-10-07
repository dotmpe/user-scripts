#!/usr/bin/env bash
# Created: 2018-11-14
# Main project build frontend for U-S
set -euETo pipefail
shopt -s extdebug

# The main project redo script controls project lifecycle and workflows.

version="User-Scripts/0.1-alpha"

default_do_include () # Build-Part Target-File Target-Name Temporary
{
  local build_part="$1"

  $LOG "info" ":part:$2" "Building include" "$1"
  build-ifchange "$build_part" || return
  shift

  $LOG "debug" ":part:$1" "Sourcing include" "$build_part"
  source "$build_part"
}

default_do_main ()
{
  # TODO: replace this with definitive tools/redo/env.sh file
  CWD=$PWD
  #. "${_LOCAL:="${UCONF:-"$HOME/.conf"}/etc/profile.d/_local.sh"}" || return
  export UC_QUIET=0
  export v=${v:-3}
  export UC_LOG_LEVEL=$v
  export STDLOG_UC_LEVEL=$v
  export UC_SYSLOG_OFF=1
  export UC_LOG_BASE="redo[$$]:default.do"

  #. "${CWD}/tools/redo/env.sh" || return

  #ENV_NAME=redo . ./.meta/package/envs/main.sh || return

  #. "${UCONF:-"$HOME/.conf"}/etc/profile.d/_local.sh" || return

  command -v build- >/dev/null || build- () {
    build_entry_point=build- \
      source "${U_S:?}/src/sh/lib/build.lib.sh"; }

  true "${BUILD_TOOL:=redo}"
  true "${BUILD_TARGET:=$1}"

  # TODO: use boot-for-target to load script deps
  redo_env="$(quiet=true build- boot)" || {
    $LOG "error" "" "While loading build-env" "E$?" $?
    return
  }

  eval "$redo_env" || {
    $LOG "error" "" "While reading build-env" "E$?" $?
    return
  }

  # Keep short build sequences in this file (below in the case/easc), but move
  # larger build-scripts to separate files to prevent unnecessary builds from
  # updates to the default.do
  # Alternatively we fall back to build-components from build.lib.sh that reads
  # rules to generate source-to-target build specs.

  local target="$(echo ${BUILD_TARGET:?} | tr './' '_')" part
  part=$( build_part_lookup $target.do ${build_parts_bases:?} ) && {

    { build_init__redo_env_target_ || return
      build_init__redo_libs_ "$@" || return
    } >&2

    $LOG "notice" ":part:$1" "Building part" "$PWD:$0:$part"
    default_do_include $part "$@"
    exit $?
  }

  $LOG "info" ":main:$1" "Selecting target" "$PWD:$0"
  case "$1" in

    # 'all' is the only special redo-builtin (it does not show up in
    # redo-{targets,sources}), everything else are proper targets. Anything
    # seems to be accepted, '-' prefixed arguments are parsed as redo options
    # but after '--' to separate arguments those can start with '-' as well.

    :env )     build-always && build_env_sh >&2  ;;
    :info )    build-always && build_info ;;
    :sources ) build-always && build-sources >&2 ;;
    :targets ) build-always && build-targets >&2 ;;
    # XXX: see also build-whichdo, build-log

    help|:help )    build-always
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


    # Build without other do-files, based on .build-rules.txt
    * )
        build_rules_for_target "$@" || return

        test "$1" != "${BUILD_RULES-}" -a -s "${BUILD_RULES-}" || {
          # Prevent redo self.id != src.id assertion failure
          $LOG alert ":build-component:$1" \
            "Cannot build rules table from empty table" "${BUILD_RULES-null}" 1
          return
        }

        # Shortcut execution for simple aliases, but takes literal values only
        { build_init__redo_env_target_ || return
        } >&2
        build_env_rule_exists "$1" && {
          build_env_targets
          exit
        }

        # Run build based on matching rule in BUID_RULES table

        build_rule_exists "$1" || {
          #print_err "error" "" "Unknown target, see '$BUILD_TOOL help'" "$1"
          $LOG "error" "" "Unknown target, see '$BUILD_TOOL help'" "$1" $?
          return
        }

        $LOG "notice" ":exists:$1" "Found build rule for target" "$1"

        { build_init__redo_libs_ "$@" || return
        } >&2
        build_components "$1" "" "$@"
        exit
      ;;

  esac
}

default_do_main "$@"

# Id: U-s:default.do                                               ex:ft=bash:
