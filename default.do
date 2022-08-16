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
  # XXX:
  CWD=$PWD
  #. "${_LOCAL:="${UCONF:-"$HOME/.conf"}/etc/profile.d/_local.sh"}" || return
  export UC_QUIET=0
  export v=${v:-3}
  export UC_LOG_LEVEL=$v
  export STDLOG_UC_LEVEL=$v
  export UC_SYSLOG_OFF=1
  export UC_LOG_BASE="redo[$$]:default.do"

  ENV_NAME=redo

  . "${CWD}/tools/redo/env.sh" || return

  #ENV_NAME=redo . ./.meta/package/envs/main.sh || return

  . "${UCONF:-"$HOME/.conf"}/etc/profile.d/_local.sh" || return

  # Keep short build sequences in this file (below in the case/easc), but move
  # larger build-scripts to separate files to prevent unnecessary builds from
  # updates to the default.do

  local target="$(echo $REDO_TARGET | tr './' '_')" part
  part=$( lookup_exists $target.do $build_parts_bases ) && {

    $LOG "notice" ":part:$1" "Building part" "$PWD:$0:$part"
    default_do_include $part "$@"
    exit $?
  }

  $LOG "notice" ":main:$1" "Building target" "$PWD:$0"

  case "$1" in

    help )    build-always
              echo "Usage: $package_build_tool [${build_main_targets// /|}]" >&2
      ;;

    # Default build target
    all )     build-always && build $build_all_targets
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

    # Integrate other script targets or build other components by name,
    # without additional redo files (using components-txt and build-component).
    # See U-s:build.lib.sh
    * )
        # FIXME: this taints every target in the components-txt every time
        # some (other?) rule is updated a bit. There has to be a better way.

        test "${components_txt_build:=0}" = "1" && {
          build-ifchange $components_txt || return
        } || {
          test "$components_txt_build" = "0" || {
            build-ifchange $components_txt_build || return
          }
        }

        test "$1" != "${components_txt-}" -a -s "${components_txt-}" || {
          $LOG alert ":build-component:$1" \
            "Cannot build from table w/o table" "${components_txt-null}" 1
          return
        }

        build_component_exists "$1" && {
          $LOG "notice" ":exists:$1" "Found component " "$1"
          build_components "$1" "" "$@"
          return $?
        } || true

        print_err "error" "" "Unknown target, see '$package_build_tool help'" "$1"
        return 1
      ;;

  esac
}

default_do_main "$@"

# Id: U-s:default.do                                               ex:ft=bash:
