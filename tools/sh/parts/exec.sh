#!/bin/sh


# Execute command as part of SUITE/stage/sq, and handle start/after-pass/fail
# LOG verbosity (except if quiet=1). This is to execute frontend functions,
# skip on dry-run/no-act
# left to the subcmd handler or nested functions.
sh_exec() # Exec fe-cmd ~ Command-Line...
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
