#!/bin/sh

# std: logging and dealing with the shell's stdio decriptors


std_lib_load ()
{
  # The deeper get within subshells, the more likely stdio is re-routed from
  # tty. This test should be performed in the scripts main.
  true "${std_interactive:=std_term 0}"

  # Result of std_interactive test. Defaulted in init.
  #STD_INTERACTIVE=[01]

  true "${STD_E:=GE SH CE CN IAE ESOOR}"
  true "${STD_E_SIGNALS:="HUP INT QUIT ILL TRAP ABRT IOT BUS FPE KILL USR1 SEGV\
 USER2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM\
 PROF WINCH IO POLL PWR LOST"}"

  $INIT_LOG debug "" "Loaded std-uc.lib" "$0"
}

std_lib_init ()
{
  test -n "${INIT_LOG-}" || return 109
  test -x "$(which readlink)" || error "readlink util required for stdio-type" 1
  test -x "$(which file)" || error "file util required for stdio-type" 1
  test -n "${LOG-}" && std_lib_log="$LOG" || std_lib_log="$INIT_LOG"
  test -z "${v-}" || verbosity=$v

  true "${STD_INTERACTIVE:=`eval "$std_interactive"; printf "%i" $?`}"

  std_uc_env_def &&
  $INIT_LOG debug "" "Initialized std.lib" "$0"
}


std_lib_check()
{
  std_iotype_check
}

# XXX: use as part of std suite?
  # stdio_0_type= stdio_1_type= stdio_2_type=
  # std.lib.sh
  #{
  #    stdio_type 0 $$ &&
  #    stdio_type 1 $$ &&
  #    stdio_type 2 $$
  #} || return

# Check for Linux, MacOS or Cygwin.
std_iotype_check()
{
  case "$uname" in

    Linux | CYGWIN_NT-* ) ;;
    Darwin ) ;;

    * ) error "No stdio-type for $uname" ;;
  esac
  return 1
}


std_uc_env_def ()
{
  local key

  # Set defaults for status codes
  # XXX: need better variable name convention if integrated with +U-s
  # Like STD_* for software defined and _STD_ for user-defined or local script
  # static variables. See also stdlog discussion on more idiomatic flows.

  for key in ${STD_E} ${STD_E_SIGNALS}
  do
    vref=UC_DEFAULT_${key^^}
    declare $vref=false
    #declare $vref=true
    #val=${!vref-} || continue
    #echo "val='$val'" >&2
  done

  : "${_E_GAE:=193}" # Generic Argument Error. Value error, unspecific.
  : "${_E_MA:=194}" # Missing arguments. Syntax error. Was 64 in places.
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

    Linux | CYGWIN_NT-* )
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

    Darwin )

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


# Test if all [given] stdio are at terminal.
std_term () # ~ [0] [1] [2]...
{
  test $# -gt 0 || set -- 0 1 2
  test -n "$*" || return ${_E_GAE}

  local tty
  while test $# -gt 0
  do
    test -t $1 || tty=false
    shift
  done
  ${tty:-true}
}

# Was var_log_key()
log_src_id_var()
{
  test -n "${log_key-}" || {
    test -n "${stderr_log_channel-}" && {
      log_key="$stderr_log_channel"
    } || {
      test -n "${base-}" || {
        base="\$scriptname[\$\$]"
      }
      test -n "$base" && {
        test -n "${scriptext-}" || scriptext=.sh
        log_key=\$base\$scriptext
      } || echo "Cannot get var-log-key" 1>&2;
    }
  }
}

log_src_id()
{
  eval echo \"$log_key\"
}

log_bw()
{
  echo "$1"
}

log_16()
{
  printf -- "%s\n" "$1"
}

log_256()
{
  printf -- "%s\n" "$1"
}

# stdio helper functions
log()
{
  test -n "${log_key:-}" || log_src_id_var
  printf -- "%s[%s] %s %s\n" "$bb" "$bk$(log_src_id)$bb" "${norm-}" "$1"
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
        bb=${yellow-}; bk=${default-}
        test "$CS" = "light" \
          && crit_label_c="\033[38;5;226;48;5;249m" \
          || crit_label_c="${yellow-}"
        log "${bld-}${crit_label_c}$1${norm-}${blackb-}: ${bdefault-}$2${norm-}" 1>&2 ;;
    err*)
        bb=${red-}; bk=${grey-}
        log "${bld-}${red-}$1${blackb-}: ${norm-}${bdefault-}$2${norm-}" 1>&2 ;;
    warn*|fail*)
        bb=${darkyellow-}; bk=${grey-}
        test "$CS" = "light" \
            && warning_label_c="\033[38;5;255;48;5;220m"\
            || warning_label_c="${darkyellow-}";
        log "${bld-}${warning_label_c}$1${norm-}${grey-}${bld-}: ${default-}$2${norm-}" 1>&2 ;;
   notice )
        bb=${purple-}; bk=${grey-}
        log "${grey-}${default-}$2${norm-}" 1>&2 ;;
    info )
        bb=${blue-}; bk=${grey-}
        log "${grey-}$2${norm-}" 1>&2 ;;
    ok|pass* )
        bb=${grn-}; bk=${grey-}
        log "${bold-}$bb$1${norm-}${default-} $2${norm-}" 1>&2 ;;
    * )
        bb=${drgrey-} ; bk=${grey-}
        log "${grey-}$2${norm-}" 1>&2 ;;

  esac
  test -z "${3-}" || {
    exit $3
  }
}


# std-v <level>
# if verbosity is defined, return non-zero if <level> is below verbosity treshold
std_v() # Log-Level
{
  test -z "${verbosity:-${v:-}}" && return || {
    test ${verbosity:-${v:-}} -ge $1 && return || return 1
  }
}

std_exit () # [exit-at-level]
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
  std_v 1 && stderr "Emerg" "$1" ${2-}
  std_exit ${2-}
}
crit()
{
  local log=; req_init_log
  std_v 2 && stderr "Crit" "$1" ${2-}
  std_exit ${2-}
}
error()
{
  local log=; req_init_log
  std_v 3 && stderr "Error" "$1" ${2-}
  std_exit ${2-}
}
warn()
{
  local log=; req_init_log
  std_v 4 && stderr "Warning" "$1" ${2-}
  std_exit ${2-}
}
note()
{
  local log=; req_init_log
  std_v 5 && stderr "Notice" "$1" ${2-}
  std_exit ${2-}
}
std_info()
{
  local log=; req_init_log
  std_v 6 && stderr "Info" "$1" ${2-}
  std_exit ${2-}
}
debug()
{
  local log=; req_init_log
  std_v 7 && stderr "Debug" "$1" ${2-}
  std_exit ${2-}
}

std_batch_mode ()
{
  test ${STD_BATCH_MODE:-0} -eq 1 -o ${STD_INTERACTIVE:-0} -eq 0
}

std_bash_status ()
{
  std_signals | awk ' { print 128+$1" "$2 } '
}

std_signals ()
{
  /bin/sh -c "kill -l" |
      nl -w 1 -s ' ' -v 0
  return

  # Identical with bash (only in non-/bin/sh mode)
  /bin/bash -c "kill -L" | tr -s ' \n\t' ' ' |
      sed '
         s/ *\([0-9][0-9]*\)) SIG\([^ ]*\) /\1 \2\n/g
      '
}

#
