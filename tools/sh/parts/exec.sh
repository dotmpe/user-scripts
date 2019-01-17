#!/bin/sh


# Execute command verbosely logging start end after pass/fail. Except if quiet.
# This is intended to execute frontend functions, skipping on dry-run/no-act is
# left to the subcmd handler or nested functions.
sh_exec()
{
  test "${quiet:-}" = "1" ||
    $LOG note "" "Starting $SUITE ${stage:-} ${seq:-}..." "$*"
  "$@" && {
      test "${quiet:-}" = "1" ||
        $LOG pass "" "$SUITE ${stage:-} ${seq:-}" "$*"
    } || {
      test "${quiet:-}" = "1" && return $? ||
        $LOG fail "" "$SUITE ${stage:-} ${seq:-}" "$*" $?
    }
}

# Id: U-S:tools/sh/parts/exec.sh               ex:filetype=bash:colorcolumn=80:
