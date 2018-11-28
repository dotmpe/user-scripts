#!/bin/sh

# Module to provide basic LOG routine. This merges old mkdocs log and script std.lib

logger_lib_load()
{
  test -n "$logger_log_hooks" || logger_log_hooks=stderr

  test -n "$logger_exit_threshold" || logger_exit_threshold=4

  test -n "$logger_log_threshold" || logger_log_threshold=9 # Everything
}


# Wrapper function for logger handler(s). Output and/or relay behaviour is by
# actual handler, multiple may be handled the messeage in sequence.
#
# Normal mode is to exit on any status-code given or returned by
# logger handler.
logger_log() # level target-ids description source-ids status-code
{
  { test -z "$1" || {
      test $1 -le $logger_log_threshold
    }
  } && {

    local r= logger_hook=

    for logger_hook in $logger_log_hooks
    do
        logger_${logger_hook} "$1" "$2" "$3" "$4" "$5" || r="$r$?"
    done

    test -z "$r" -o -z "$5" || {
      $LOG "error" "logger" "Exit triggered by log hook(s) '$r'" "$logger_log_hooks" "$r"
      set -- "$1" "$2" "$3" "$4" "1"
    }
  }

  test -n "$5" && exit $5
  test -z "$1" || {
    test $1 -gt $logger_exit_threshold || exit -$1
  }
}

logger_man_5__theme='The builtin stderr logger supports templates, which are
printf formats with embedded env-var references. Evaluated before calling
printf, the placeholders expand to whatever ANSI code required to set a terminal
color or style.


'

logger_stderr_tpl_emerg='${yellow}[${default}%s${yellow}] Emergency: ${normal}%s'
logger_stderr_tpl_emerg_rule=$logger_stderr_tpl_emerg' <%s>${normal}'

logger_stderr_tpl_crit='${yellow}[${default}%s${yellow}] Critical: ${normal}%s'
logger_stderr_tpl_crit_rule=$logger_stderr_tpl_crit' <%s>${normal}'

logger_stderr_tpl_error='${red}[${grey}%s${red}] ${bold}Error${black}: ${normal}%s'
logger_stderr_tpl_error_rule=$logger_stderr_tpl_error' <%s>${normal}'

logger_stderr_tpl_warn='${darkyellow}[${grey}%s${darkyellow}] ${bold}Warning${black}: ${normal}%s'
logger_stderr_tpl_warn_rule=$logger_stderr_tpl_warn' <%s>${normal}'

logger_stderr_tpl_note='${purple}[${grey}%s${purple}] ${bold}Note${black}: ${normal}%s'
logger_stderr_tpl_note_rule=$logger_stderr_tpl_note' <%s>${normal}'

logger_stderr_tpl_info='${blue}[${grey}%s${blue}] ${bold}Info${black}: ${normal}%s'
logger_stderr_tpl_info_rule=$logger_stderr_tpl_info' <%s>${normal}'

logger_stderr_tpl_debug='${darkgrey}[%s] ${grey}Debug${black}: ${grey}%s'
logger_stderr_tpl_debug_rule=$logger_stderr_tpl_debug' <%s>${normal}'


# A printf logger, with builtin templates for stderr: a user console 'log' fmt.
logger_strfmt() # line-type target-ids description source-ids
{
  local linetype= linetpl_base=logger_stderr_ tpl=
  test -z "logger_hook" || linetpl_base="logger_${logger_hook}_"

  test -n "$1" || set -- "$logger_log_threshold" "$2" "$3" "$4" "$5"

  fnmatch "[0-9]" "$1" && {
    type_name="$1"
    type_num="$(${linetpl_base}num "$1")"
  } || {
    type_name="$(${linetpl_base}level "$1")"
    type_num="$1"
  }
  shift

  tpl="$(eval echo \"\$${linetpl_base}tpl_${type_name}\")"
  test -n "$tpl" || $LOG "error" "lib" "Getting tpl ${type_name}" "" 1

  test -n "$3" && {

    eval printf -- \"$tpl\\n\" \""$1"\" \""$2"\" \""$3"\"
  } || {

    eval printf -- \"$tpl\\n\" \""$1"\" \""$2"\"
  }
  true
}


# A logger with old error/warn/note/debug usage; dont print if verbosity
# is too low; exit with given status.
logger_stderr() # syslog-level target-ids description source-ids status-code
{
  test -n "$1" || set -- "$stderr_log_level" "$2" "$3" "$4" "$5"
  test -n "$stderr_log_channel" || stderr_log_channel="$1"
  test -n "$2" || set -- "$1" "$stderr_log_channel" "$3" "$4" "$5"

  logger_hook=stderr logger_strfmt "$@" >&2
}


# Return level number as string for use with line-type or logger level, channel
logger_stderr_level() # Level-Num
{
  case "$1" in
      1 ) echo emerg ;;
      2 ) echo crit ;;
      3 ) echo error ;;
      4 ) echo warn ;;
      5 ) echo note ;;
      6 ) echo info ;;
      7 ) echo debug ;;
      * ) return 1 ;;
  esac
}

logger_stderr_num() # Level-Name
{
  case "$1" in
      emerg ) echo 1 ;;
      crit  ) echo 2 ;;
      error ) echo 3 ;;
      warn  ) echo 4 ;;
      note  ) echo 5 ;;
      info  ) echo 6 ;;
      debug ) echo 7 ;;
      * ) return 1 ;;
  esac
}


# Go over levels 1-7 and demo logger-log
logger_demo()
{
  for level in $(seq 7 1)
  do
    #logger_stderr 5 logger:demo "$level"
    logger_log "$level" "logger:demo" "$(logger_stderr_level $level) demo line"
    #logger_stderr "$level" "logger:demo" "$(logger_stderr_level $level) demo line"
  done
}

logger_check()
{
  eval "$@" "$logger_fd>/dev/null"
}
