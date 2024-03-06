## Local mapping rules and development for new inline default.do parts.

case "${1:?}" in

  # - ) ;;


  .build/tests/*.tap )
        build_target__seq__source_do "tools/redo/recipes/_build_tests_*.tap.do" ;;


  src/md/man/User-Script:*-overview.md )
        build_target__seq__source_do "tools/redo/recipes/src_man_man7_User-Script:*-overview.md.do" ;;

  src/man/man7/User-Script:*.7 )
        build_target__seq__source_do "tools/redo/recipes/src_man_man7_User-Script:*.7.do" ;;

  src/man/man*/*.* )
        build_target__seq__source_do "tools/redo/recipes/src_man_man*_*.*.do" ;;

  * ) return ${_E_next:-196}

esac
