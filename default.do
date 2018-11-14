#!/bin/sh
redo-always

# The main project redo script controls project lifecycle and workflows


default_main()
{
  local script_util=$HOME/bin/tools/sh
  
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


    init ) redo build-init build-init-checks
      ;;
  
    check ) redo build-check
      ;;
  
    build ) redo build-build
      ;;
  
    baselines )   .build.sh run_test baselines ;;
    lint )        test/lint.sh default ;;
    units )       .build.sh run_test units ;;
    specs )       .build.sh run_test specs ;;
  
    test ) .build.sh run_test ;;
    #test ) redo baselines units specs ;;
  
    pack ) redo build-pack
      ;;
  
    dist ) redo build-dist
      ;;
 

    build-* ) ./.build.sh "$(echo "$1" | cut -c7- )" ;;


    x-* ) exec $script_util/init-here.sh /src "$(cat <<EOM
lib_load
lib_load package build-test

EOM
)" ;;


    # TODO: build components by name, maybe specific module specs
    * ) redo help
        exit 1
      ;;
  
  esac
}


default_main "$@"
