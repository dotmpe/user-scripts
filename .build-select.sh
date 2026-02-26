## Local mapping rules and development for new inline default.do parts.

sh_mode strict

us_env_build

# Canonical, localized path
: "${XREDO_TARGET#"$XREDO_BUILD"}"
XREDO_BUILD_TARGET=$B/${XREDO_NODE:?}


# Inline: -xredo-env,uc.sh

case "${XREDO_TARGET}" in
#case "${1:?}" in

  ?* )
        uc_env_2625 -Q "${XREDO_TARGET:1}"
    ;;

  +* )
        proj=${REDO_TARGET%%:*}
        subtarget=${REDO_TARGET#*:}
        (
          set -- "$subtarget"
					xredo_unset_buildvars
					cd "$HOME/htdocs" && redo "$@"
			  )
			  # XXX: there is no way currently to get actual build-changes (using
        # redo-stamp), could want/need some sort of access but this build
        # should probably know about that internally
			  redo-always
    ;;

  -* ) false ;;
  # - ) ;;


  .build/tests/*.tap )
        build_target__seq__source_do "tool/redo/recipe/_build_tests_*.tap.do" ;;


  src/md/man/User-Script:*-overview.md )
        build_target__seq__source_do "tool/redo/recipe/src_man_man7_User-Script:*-overview.md.do" ;;

  src/man/man7/User-Script:*.7 )
        build_target__seq__source_do "tool/redo/recipe/src_man_man7_User-Script:*.7.do" ;;

  src/man/man*/*.* )
        build_target__seq__source_do "tool/redo/recipe/src_man_man*_*.*.do" ;;

  * ) return ${_E_next:-196}

esac
