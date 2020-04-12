#!/bin/sh

# Logger - arg-to-colored ansi line output
# Usage:
#   log.sh [Line-Type] [Header] [Msg] [Ctx] [Exit]


test -n "$verbosity" || {
  test -z "$v" || verbosity="$v"
}
test -n "$verbosity" || {
  test -n "$DEBUG" && verbosity=7 || verbosity=6
}


# Return level number as string for use with line-type or logger level, channel
log_level_name() # Level-Num
{
  case "$1" in
      1 ) echo emerg ;;
      2 ) echo crit ;;
      3 ) echo error ;;
      4 ) echo warn ;;
      5 ) echo note ;;
      6 ) echo info ;;
      7 ) echo debug ;;

      5.1 ) echo ok ;;
      4.2 ) echo fail ;;
      3.3 ) echo err ;;
      6.4 ) echo skip ;;
      2.5 ) echo bail ;;
      7.6 ) echo diag ;;

      * ) return 1 ;;
  esac
}

log_level_num() # Level-Name
{
  case "$1" in
      emerg ) echo 1 ;;
      crit  | bail ) echo 2 ;;
      error | err ) echo 3 ;;
      warn  | fail ) echo 4 ;;
      note  | notice | ok ) echo 5 ;;
      info  | skip | TODO ) echo 6 ;;
      debug | diag ) echo 7 ;;

      * ) return 1 ;;
  esac
}

# set log-key to best guess
log_src_id_key_var()
{
  test -n "${log_key-}" || {
    test -n "${stderr_log_channel-}" && {
      log_key="$stderr_log_channel"
    } || {
      test -n "${base-}" -a -z "$scriptname" || {
        log_key="\$CTX_PID:\$scriptname"
      }
      test -n "$log_key" || {
        test -n "${scriptext-}" || scriptext=.sh
        log_key="\$base\$scriptext"
      }
      test -n "$log_key" || echo "Cannot get log-src-id key" 1>&2;
    }
  }
}

log_src_id()
{
  eval echo \"$log_key\"
}


__log() # [Line-Type] [Header] [Msg] [Ctx] [Exit]
{
  test -n "$2" || {
    test -n "${log_key:-}" || log_src_id_key_var
    test -n "$2" || set -- "$1" "$(log_src_id)" "$3" "$4" "$5"
  }
  lvl=$(log_level_num "$1")
  test -z "$lvl" -o -z "$verbosity" || {
    test $verbosity -ge $lvl || {
      test -n "$5" && exit $5 || {
        return 0
      }
    }
  }

  indent=""
  linetype=$(echo $1 | tr '[:upper:]' '[:lower:]')

  case "$linetype" in

    emerg|crit| error|warn|warning )
        prefix="[$2] $1:"
      ;;

    note|info|debug )
        prefix=" $2:"
      ;;

    ok|pass|passed )
        prefix="[$2] OK"
        test -z "$3" || prefix="$prefix:"
      ;;

    not[_-]ok|nok|fail|failed )
        prefix="[$2] Failed"
        test -z "$3" || prefix="$prefix:"
      ;;

    file[_-]ok|file[_-]pass|file[_-]passed )
        prefix="<$2> OK"
        test -z "$3" || prefix="$prefix:"
      ;;

    file[_-]not[_-]ok|file[_-]nok|file[_-]fail|file[_-]failed )
        prefix="<$2> Failed"
        test -z "$3" || prefix="$prefix:"
      ;;

  esac

  test -z "$4" && suffix="" || suffix="$4"

  test -n "$suffix" && {
    printf "%s%s %s <%s>\n" "$indent" "$prefix" "$3" "$suffix" >&2
  } || {
    printf "%s%s %s\n" "$indent" "$prefix" "$3" >&2
  }

  unset lvl linetype prefix indent suffix
  test -z "$5" || exit $5
}


# Start in stream mode or print one line and exit.
if test "$1" = '-'
then
  export IFS="	"; # tab-separated fields for $inp
  while read lt p m c s;
  do
    __log "$lt" "$p" "$m" "$c" "$s";
  done
else
  case "$1" in
    demo )
        set -- demo "Test message line" "123"
        __log "error" "$@"
        __log "warn" "$@"
        __log "note" "$@"
        __log "info" "$@"
        __log "debug" "$@"
        __log "ok" "$@"
        __log "fail" "$@"
      ;;
    * )
        __log "$1" "$2" "$3" "$4" "$5"
      ;;
  esac
fi
# user-scripts/0.0.2-dev tools/sh/log.sh
