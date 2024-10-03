sh_mode dev strict

true "${GITDIR:=$(git rev-parse --git-dir)}"

test -d "${GITDIR:?}" ||
  $LOG error :%%.git.scm "Need Git dir" "${BUILD_BASE:?}" 1 || return

declare bn
bn="$(basename "${1:?}" .git.scm)"

#test "${bn:1}"
_git_scm ()
{
  case "${1:?}" in

  ( describe )
        _git_scm "ifchange-HEAD" || return
        git describe --always
      ;;

  ( ifchange-HEAD )
        build-ifchange "${GITDIR:?}/HEAD" || return
      ;;

  ( ifchange-index )
        build-ifchange "${GITDIR:?}/index" || return
      ;;

  ( index )
        _git_scm "ifchange-index" || return
        build-stamp < "${GITDIR:?}/index"
      ;;

  ( stage.md5 )
        _git_scm "ifchange-index" || return
        printf git:
        git describe --always && git status | md5sum - | awk '{print $1}'
      ;;

  ( stage )
        _git_scm "ifchange-index" || return
        printf git:
        git describe --always && git status
      ;;


  ( debug )
        {
          echo ${BUILD_TARGET:?}
          echo ${BUILD_SPEC:?}
        } >&2
        false
      ;;
  esac
}

_git_scm "$bn" >"${3:?}"
test -s "$3" && redo-stamp <"$3" || rm "$3"

#
