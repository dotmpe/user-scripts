#!/usr/bin/env bash
redo-always

set -o nounset
set -o pipefail
set -o errexit


# The main project redo script controls project lifecycle and workflows


default_main()
{
  export package_build_tool=redo
  #scriptpath=$PWD
  #script_util=$scriptpath/tools/sh

  : "${BASH_ENV:=.htd/env.sh}"
  . $BASH_ENV
  export BASH_ENV

  fnmatch "*redo:*" "$scriptname" || scriptname=$scriptname:redo
  export scriptname=$scriptname:$1

  case "$1" in
  
    # Default redo target
    all ) echo "Building $1 targets (but stopping before dist)" >&2
        redo init check build test pack
      ;;
  
    help ) echo "Usage: redo [help|all|default|current|init|check|build|test|pack|dist]" >&2
      ;;


    default ) redo build-default
      ;;
  
    current ) redo build-current
      ;;


    init )    
              redo build-init build-check
      ;;
  
    check )
              redo build-check build-check
      ;;
  
    build ) 
              redo-ifchange build-check &&
              redo build-build
      ;;
  
    baselines )   
              ./.build.sh negative &&
              ./test/base.sh all
      ;;

    lint )        test/lint.sh all ;;
    units )       test/unit.sh all ;;
    specs )       test/spec.sh all ;;
  
    test )        
              redo-ifchange init &&
              redo-ifchange build &&
              ./.build.sh run-test >&2
      ;;

    pack )
              redo-ifchange build-test &&
              redo build-pack
      ;;
  
    dist )
              redo-ifchange build-pack &&
              redo build-dist
      ;;
 

    build-* )     ./.build.sh "$(echo "$1" | cut -c7- )" ;;


    x-* ) exec $script_util/init-here.sh /src "$(cat <<EOM
lib_load package build-test

EOM
)" ;;


    # TODO: build components by name, maybe specific module specs
    * ) redo help
        exit 1
      ;;
  
  esac
}

SCRIPTPATH= default_main "$@"
