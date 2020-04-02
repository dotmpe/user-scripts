#!/bin/sh

# std: logging and dealing with the shell's stdio decriptors


std_lib_load()
{
  test -n "${uname-}" || uname="$(uname -s | tr '[:upper:]' '[:lower:]')"
}

std_lib_init()
{
  test "${std_lib_init-}" = "0" || {
    test -n "${INIT_LOG-}" || return 109
    test -x "$(which readlink)" || error "readlink util required for stdio-type" 1
    test -x "$(which file)" || error "file util required for stdio-type" 1
    test -n "${LOG-}" && std_lib_log="$LOG" || std_lib_log="$INIT_LOG"
    $INIT_LOG debug "" "Initialized std.lib" "$0"
  }
}

std_lib_check()
{
  std_iotype_check
}


std_iotype_check()
{
  case "$uname" in

    linux | cygwin_nt-* ) ;;
    darwin ) ;;

    * ) error "No stdio-type for $uname" ;;
  esac
  return 1
}


# TODO: probably also deprecate, see stderr. Maybe other tuil for this func.
# stdio type detect - return char t(erminal) f(ile) p(ipe; or named-pipe, ie. FIFO)
# On Linux, uses /proc/PID/fd/NR: Usage: stdio_type NR PID
# On OSX/Darwin uses /dev/fd/NR: Usage: stdio_type NR
# IO: 0:stdin 1:stdout 2:stderr

get_stdio_type() # IO-Num PId
{
  test -z "${2-}" || {
    test $$ -eq $2 || return
  }
  eval echo \$stdio_${1}_type
}

stdio_type()
{
  local io= pid=
  test -n "$1" && io=$1 || io=1
  case "$uname" in

    linux | cygwin_nt-* )
        test -n "${2-}" && pid=$2 || pid=$$
        test -e /proc/$pid/fd/${io} || error "No $uname FD $io"
        if readlink /proc/$pid/fd/$io | grep -q "^pipe:"; then
          eval stdio_${io}_type=p
        elif file $( readlink /proc/$pid/fd/$io ) | grep -q 'character.special'; then
          eval stdio_${io}_type=t
        else
          eval stdio_${io}_type=f
        fi
      ;;

    darwin )

        test -e /dev/fd/${io} || error "No $uname FD $io"
        if file /dev/fd/$io | grep -q 'named.pipe'; then
          eval stdio_${io}_type=p
        elif file /dev/fd/$io | grep -q 'character.special'; then
          eval stdio_${io}_type=t
        else
          eval stdio_${io}_type=f
        fi
      ;;

    * ) error "No stdio-type for $uname" ;;
  esac
}

var_log_key()
{
  test -n "${log_key-}" || {
    test -n "${log-}" && {
      log_key="$log"
    } || {
      test -n "${base-}" || base=$scriptname
      test -n "$base" && {
        test -n "${scriptext-}" || scriptext=.sh
        log_key=$base$scriptext
      } || echo "Cannot get var-log-key" 1>&2;
    }
  }
}

log_bw()
{
  echo "$1"
}

log_16()
{
  printf -- "$1\n"
}

log_256()
{
  printf -- "$1\n"
}

# Normal log uses log_$TERM
# 1:str 2:exit
_log()
{
  test -n "$1" || exit 201
  test -n "$stdout_type" || stdout_type="$stdio_1_type"
  test -n "$stdout_type" || stdout_type=t

  local key=
  test -n "$SHELL" \
    && key="$scriptname.$(basename -- "$SHELL")" \
    || key="$scriptname.(sh)"

  case $stdout_type in
    t )
        test -n "$subcmd" && key=${key}${bb}:${bk}${subcmd}
        if test $LOG_TERM = bw
        then
            log_$LOG_TERM "[${key}] $1"
        else
            log_$LOG_TERM "${bb}[${bk}${key}${bb}] ${norm}$1"
        fi
      ;;

    p|f )
        test -n "$subcmd" && key=${key}${bb}:${bk}${subcmd}
        if test $LOG_TERM = bw
        then
            log_$LOG_TERM "# [${key}] $1"
        else
            log_$LOG_TERM "${bb}# [${bk}${key}${bb}] ${norm}$1"
        fi
      ;;
  esac
}

# stdio helper functions
log()
{
  var_log_key
  printf -- "[$log_key] $1\n"
  unset log_key
}

err()
{
  warn "err() is deprecated, see stderr()"
  # TODO: turn this on and fix tests warn "err() is deprecated, see stderr()"
  log "$1" 1>&2
  test -z "${2-}" || exit $2
}

_stderr()
{
  case "$(echo $1 | tr 'A-Z' 'a-z')" in
    warn*|err*|notice ) err "$1: $2" "$3" ;;
    * ) err "$2" "$3" ;;
  esac
}
# FIXME: move all highlighting elsewhere / or transform/strip for specific log-TERM
stderr() # level msg exit
{
  test $# -le 3 || {
    echo "Surplus arguments '$4'" >&2
    exit 200
  }

  fnmatch "*%*" "$2" && set -- "$1" "$(echo "$2" | sed 's/%/%%/g')" "${3-}"
  # XXX seems ie grep strips colors anyway?
  test -n "${stdout_type-}" || stdout_type=${stdio_2_type-t}
  case "$(echo $1 | tr 'A-Z' 'a-z')" in

    crit*)
        bb=${ylw}; bk=$default
        test "$CS" = "light" \
          && crit_label_c="\033[38;5;226;48;5;249m" \
          || crit_label_c="${ylw}"
        log "${bld}${crit_label_c}$1${norm}${blackb}: ${bdefault}$2${norm}" 1>&2 ;;
    err*)
        bb=${red}; bk=$grey
        log "${bld}${red}$1${blackb}: ${norm}${bdefault}$2${norm}" 1>&2 ;;
    warn*|fail*)
        bb=${dylw}; bk=$grey
        test "$CS" = "light" \
            && warning_label_c="\033[38;5;255;48;5;220m"\
            || warning_label_c="${dylw}";
        log "${bld}${warning_label_c}$1${norm}${grey}${bld}: ${default}$2${norm}" 1>&2 ;; notice )
        bb=${prpl}; bk=$grey
        log "${grey}${default}$2${norm}" 1>&2 ;;
    info )
        bb=${blue}; bk=$grey
        log "${grey}$2${norm}" 1>&2 ;;
    ok|pass* )
        bb=${grn}; bk=$grey
        log "${default}$2${norm}" 1>&2 ;;
    * )
        bb=${drgrey} ; bk=$grey
        log "${grey}$2${norm}" 1>&2 ;;

  esac
  test -z "${3-}" || {
    exit $3
  }
}


# std-v <level>
# if verbosity is defined, return non-zero if <level> is below verbosity treshold
std_v()
{
  test -z "$verbosity" && return || {
    test $verbosity -ge $1 && return || return 1
  }
}

std_exit()
{
  test -n "${1-}" || return 0
  case "$1" in [0-9] ) ;;
    * ) $sh_tools/log.sh "error" "" "std-ext '$1'" "" 1
      return $?
      ;;
  esac
  test "$1" != "0" -a -z "$1" && return 1 || exit $1
}

emerg()
{
  local log=; req_init_log
  std_v 1 || std_exit ${2-} || return 0
  stderr "Emerg" "$1" ${2-}
}
crit()
{
  local log=; req_init_log
  std_v 2 || std_exit ${2-} || return 0
  stderr "Crit" "$1" ${2-}
}
error()
{
  local log=; req_init_log
  std_v 3 || std_exit ${2-} || return 0
  stderr "Error" "$1" ${2-}
}
warn()
{
  local log=; req_init_log
  std_v 4 || std_exit ${2-} || return 0
  stderr "Warning" "$1" ${2-}
}
note()
{
  local log=; req_init_log
  std_v 5 || std_exit ${2-} || return 0
  stderr "Notice" "$1" ${2-}
}
std_info()
{
  local log=; req_init_log
  std_v 6 || std_exit ${2-} || return 0
  stderr "Info" "$1" ${2-}
}
debug()
{
  local log=; req_init_log
  std_v 7 || std_exit ${2-} || return 0
  stderr "Debug" "$1" ${2-}
}
