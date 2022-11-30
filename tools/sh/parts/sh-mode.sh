sh_mode ()
{
  test $# -eq 0 && {
    # XXX: sh-mode summary
    echo "$0: sh-mode: $-" >&2
    trap >&2
  } || {
    declare opt
    for opt in "${@:?}"
    do
      case "${opt:?}" in
          ( build )
                sh_mode_exc $opt dev "$@"
                # Noclobber, inherit DBG/RET traps and set -e
                set -CET &&
                trap "build_error_handler" ERR || return
              ;;
          ( dev )
                sh_mode_exc $opt build "$@"
                # Hash location, inherit DBG/RET traps and set -e
                set -hET &&
                shopt -s extdebug &&
                . "${U_C}"/script/bash-uc.lib.sh &&
                trap 'bash_uc_errexit' ERR || return
              ;;
          ( strict ) set -euo pipefail || return ;;
          ( * ) stderr_ "! $0: sh-mode: Unknown mode '$opt'" 1 || return ;;
      esac
    done
  }
}
# Copy: sh-mode

sh_mode_exc ()
{
  test $# -gt 0 || return
  declare this=${1:?} other=${2:?}
  shift 2
  # TODO: store current mode
  ! fnmatch "* $other *" " $* " || {
    $LOG warn :sh-mode "Should not set both $this and $other mode"
  }
}
# Copy: sh-mode

# XXX: since we are in a function/source scope the errexit option alone does
# not prevent scripts from proceeding after an error.

# Since afaik we cannot insert implicit returns, we just make this script exit
# on error as well using a trap. That way recipe writers are forced to return
# explicitly iot. hand back control to the builder for the current build
# target.

build_error_handler ()
{
  local r=$? lastarg=$_
  #! sh_fun stderr_ ||
  #  stderr_ "! $0: Error in recipe for '${BUILD_TARGET:?}': E$r" 0
  $LOG error ":on-error" "In recipe for '${BUILD_TARGET:?}' ($lastarg)" "E$r"
  exit $r
}
# XXX:
