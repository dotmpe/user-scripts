#!/usr/bin/env bash
redo-always

set -o nounset
set -o pipefail
set -o errexit


# The main project redo script controls project lifecycle and workflows


default_main()
{
  export package_build_tool=redo

  . "${TEST_ENV:=tools/ci/env.sh}"
  export TEST_ENV

  : "${scriptname:=redo}"
  #fnmatch "*redo:*" "$scriptname" || scriptname=$scriptname:redo
  #export scriptname=$scriptname:$1

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
              redo build-init check
      ;;
  
    check )
              redo build-check
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

    
    src-sh ) # Static analysis for Sh libs

        redo-ifchange .cllct/src/sh-libs.list
        cut -d"	" -f1 .cllct/src/sh-libs.list | while read libid
        do
            redo-ifchange .cllct/src/functions/$libid-lib.func-list
            while read func
            do
              redo-ifchange .cllct/src/functions/$libid-lib/$func.func-deps
            done <.cllct/src/functions/$libid-lib.func-list
        done
      ;;


    # TODO: build components by name, maybe specific module specs
    * ) redo help
        exit 1
      ;;
  
  esac
}

# FIXME: user profile env
unset SCRIPTPATH scriptpath script_util U_S LOG
default_main "$@"
