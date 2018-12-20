#!/bin/ssh

: "${LOG:=$CWD/tools/sh/log.sh}"

test -x "$LOG" || {
  test "$LOG" = "logger_stderr" || exit 102

  $CWD/tools/sh/log.sh info "sh:env" "Reloaded existing logger env"
    . $script_util/init.sh
}

export LOG
