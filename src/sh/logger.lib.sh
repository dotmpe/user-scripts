#!/bin/sh

# Module to provide basic LOG routine. This merges old mkdocs log and script std.lib

logger_lib_load()
{
  # Default is to quit if status-code is given, set to 0 to not exit (but still
  # return false and potentially exit with set -e / -o errexit)
  test -n "$logger_exit_threshold" || logger_exit_threshold=7 # At debug

  # This would usually be copied from `verbosity` user-env setting
  #test -n "$logger_stderr_threshold" || logger_stderr_threshold=5 # At notice
  test -n "$logger_stderr_level" || logger_stderr_level=6 # At info

  # XXX: New setting for syslog hook
  test -n "$logger_log_threshold" || logger_log_threshold=3 # At error
  test -n "$logger_log_threshold" || logger_log_threshold=4 # At warning

  test -n "$logger_log_hooks" || logger_log_hooks=stderr

  lib_load logger-theme
}

#
logger_log() # line-type target-ids description source-ids status-code
{
  { test -z "$5" || { test $5 -le $logger_log_threshold ; } ; } && {

    for hook in $logger_log_hooks
    do
        logger_${hook} "$1" "$2" "$3" "$4" "$5"
    done
  }

  test -z "$5" && return
  test $5 -gt $logger_exit_threshold || exit $5
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

logger_stderr() # line-type target-ids description source-ids
{
  test -n "$5" || set -- "$1" "$2" "$3" "$4" "$logger_stderr_level"

  local linetype=
  test -n "$1" && linetype="$1" || linetype=$( logger_stderr_level "$5" )
  shift

  test -n "$3" && {

    tpl="$(eval echo \"\$logger_stderr_tpl_${linetype}_rule\")"
    eval printf -- \"$tpl\\n\" \""$1"\" \""$2"\" \""$3"\" >&2
  } || {

    tpl="$(eval echo \"\$logger_stderr_tpl_${linetype}\")"
    eval printf -- \"$tpl\\n\" \""$1"\" \""$2"\" >&2
  }
}

logger_stderr_level()
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

logger_demo()
{
  for level in $(seq 7 1)
  do
    logger_log "" "$scriptname.$(basename "$SHELL"):$TERM" \
        "$(logger_stderr_level $level) demo line" "" $level
  done
}
