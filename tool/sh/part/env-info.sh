#!/usr/bin/env bash

: "${INIT_LOG:="$LOG"}"

type lib_load >/dev/null 2>&1 &&
  $INIT_LOG "info" "sh:usr-env" "Finished. Libs:" "'${lib_loaded:-nil}'" ||
  $INIT_LOG "info" "sh:usr-env" "Finished. " ""

test -z "${DEBUG:-}" || {
  $INIT_LOG "header2" "Script-Path:" "`echo "$SCRIPTPATH"|tr ':' '\t'`"
  $INIT_LOG "header2" "Command/Shell:" "'$0'"
  $INIT_LOG "header2" "Shell Options" "'$-'"
  $INIT_LOG "header2" "Shell" "'$SHELL'"
  $INIT_LOG "header2" "TERM" "'$TERM'"
  $INIT_LOG "header2" "Shell-Level" "'$SHLVL'"
  $INIT_LOG "header2" "Keep-Going" "'$keep_going'"
}
