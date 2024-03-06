### Shell mode helper part

##

LOG_error_handler ()
{
  local r=$? lastarg=$_
  $LOG error ":on-error" "In command '${0}' ($lastarg)" "E$r"
  exit $r
}
# Copy: LOG-error-handler

# Packaged routines to prep shell.  Un profile, rc or user scripts
sh_mode ()
{
  test $# -eq 0 && {
    # XXX: sh-mode summary: flags and list traps
    echo "$0: sh-mode: $-" >&2
    trap >&2
  } || {
    # FIXME: check for conflicts with existing SHMODE, and skip existing modes
    SHMODE=${SHMODE:-$-}
    SHMODE="$SHMODE $*"
    declare opt
    for opt in "${@:?}"
    do
      case "${opt:?}" in

          ( build ) # Handler for build.lib
                sh_mode_exclusive $opt dev "$@"
                # noundef, noclobber, inherit DBG/RET traps and exitonerror
                set -uCETeo pipefail
                trap "build_error_handler" ERR || return
              ;;

          ( defs )
                  # XXX: for interactive and some particular batch or build modes
                  declare -ga env_updates=()
                  declare -ga env_defs=()
                  #declare -ga env_decl=()
              ;;

          ( dev-us )
                test -n "${U_C:-}" && {
                  sh_mode dev-uc || return
                }
              ;;

          ( dev-uc )
                sh_mode_exclusive $opt "$@"
                # Hash location, inherit DBG/RET traps and exitonerror
                set -hETe &&
                shopt -s extdebug &&
                . "${U_C:?}"/script/bash-uc.lib.sh &&
                trap 'bash_uc_errexit' ERR || return
              ;;

          ( dev )
                sh_fun stderr || stderr () { "$@" >&2; }
                test -n "${LOG-}" &&
                  $LOG info :sh-mode@dev "Development mode enabled" ||
                  stderr echo "Development mode enabled"
                test -n "${U_S:-}" && {
                  sh_mode dev-us
                  return
                } ||
                  sh_mode build
              ;;

          ( logger )
                # FIXME: bg logger
                eval "$(log.sh bg get-logger)"
              ;;

          ( log-error )
                sh_mode_exclusive $opt dev "$@"
                set -CET &&
                trap "LOG_error_handler" ERR || return
              ;;

          ( log-init )
                # Temporary setting if no LOG is configured
                test -n "${LOG:-}" && INIT_LOG=$LOG || sh_mode log-tmp || return
              ;;

          ( log-uc-start )
                # Requires lib helpers to be ready
                . ${U_C:?}/tools/sh/log.sh && uc_log_init &&
                # Unexport again, tools/sh/log.sh exec should be usable at this stage
                unset INIT_LOG LOG &&
                # Use logger function instead of sub-shell
                LOG=uc_log &&
                $LOG "info" ":sh-mode" "U-c log started" "-:$-"
              ;;

          ( log-tmp )
                # "LOG" setup with no deps
                stderr () { "$@" >&2; }
                init_log () # ~ <level> <key-> <msg> [<ctx> [<stat>]]
                { stderr echo "$@" || return; test -z "${5:-}" || return $5; }
                export -f stderr init_log
                export INIT_LOG=init_log LOG=init_log
              ;;

          ( mod )
                  sh_mode strict log-error &&
                  shopt -s expand_aliases
              ;;

          ( strict )
                  set -euo pipefail -o noclobber
              ;;

          ( isleep ) # Setup interruptable, verbose sleep command (for batch scripting)

                  trap '{ return $?; }' INT
                  # Override sleep with function
                  fun_def sleep stderr_sleep_int \"\$@\"\;
              ;;

          ( * ) stderr echo "! $0: sh-mode: Unknown mode '$opt'"; return 1 ;;
      esac
    done
  }
}
# Copy: sh-mode

sh_mode_exclusive ()
{
  test $# -gt 0 || return
  declare this=${1:?} other=${2:?}
  shift 2
  # TODO: store current mode
  ! str_globmatch " $* " "* $other *" || {
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
  : "${BUILD_TARGET:-(unset)}"
  : "${_//%/%%}"
  $LOG error ":on-error" "In recipe for '$_' ($lastarg)" "E$r"
  exit $r
}

# XXX:
export -f sh_mode{,_exclusive} LOG_error_handler build_error_handler

# Id: U-S:sh-mode
