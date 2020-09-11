#!/usr/bin/env bash
# Created: 2018-11-14
# Main project build frontend for U-S
set -euo pipefail

# The main project redo script controls project lifecycle and workflows.

version="User-Scripts/0.1-alpha"

default_do_include () # Build-Part Target-File Target-Name Temporary
{
  export scriptname=default:include:$2 build_part=$1
  build-ifchange "$build_part"
  shift
  source "$build_part"
}

default_do_main()
{
  . "${_ENV:="tools/redo/env.sh"}" || return

  # Keep short build sequences in this file (below in the case/easc), but move
  # larger build-scripts to separate files to prevent unnecessary builds from
  # updates to the default.do

  local target="$(echo $REDO_TARGET | tr './' '_')"
  local build_part="tools/$package_build_tool/parts/$target.do"
  test -e "$build_part" && {

    default_do_include $build_part "$@"
    exit $?
  }

  export scriptname=default.do:$1

  case "$1" in
  
    help )    build-always
              echo "Usage: $package_build_tool [help|all|current|init|check|build|test|pack|dist]" >&2
      ;;

    # Default build target
    all )     echo "Building $1 targets (but stopping before dist)" >&2
              build-always && build init check build test pack
      ;;
  

    current ) build-always && build build:current
      ;;


    init )    build-always && build build:init check
      ;;
  
    check )   build-always && build build:check
      ;;
  
    build )   build-always && build-ifchange build:check src-sh build:manual
      ;;
 

    baselines ) build-always &&
              ./.build.sh negative &&
              ./test/base.sh all
      ;;

    lint )        test/lint.sh all ;;
    units )       test/unit.sh all ;;
    specs )       test/spec.sh all ;;
  
    test )    build-always
              build-ifchange init &&
              build-ifchange build &&
              ./.build.sh run-test >&2
      ;;


    pack )    build-always
              build-ifchange build:test &&
              build build-pack
      ;;
  
    dist )    build-always
              build-ifchange build:pack &&
              build build:dist
      ;;


    build:* ) build-ifchange .build.sh && ./.build.sh "$(echo "$1" | cut -c7- )"
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


    # TODO: build components by name, maybe specific module specs
    * ) print_err "error" "" "Unknown target, see '$package_build_tool help'" "$1"
        return 1
      ;;
  
  esac
}

default_do_main "$@"

# Id: U-s:default.do                                               ex:ft=bash:
