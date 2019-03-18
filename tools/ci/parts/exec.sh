#!/bin/sh


# Execute frontend command, auto-start session to log pass/failed steps.
ci_exec()
{
  local r= session= suite_lbl="Command or function"
  test -e "$1" && suite_lbl=Script

  test $verbosity -le 4 ||
    print_yellow "" "Starting $suite_lbl... '$(echo $@)'"

  test -z "${SESSION_ID:-}" || session=$SESSION_ID
  test -n "$session" || sh_include start

  "$@" && {
    c-pass "Main $(echo $@)"
    trueish "${quiet:-}" ||
      print_green "" "$suite_lbl completed '$(echo $@)'"
  } || {
    c-fail "Main $*"; r=$failed_ret
    trueish "${quiet:-}" ||
      print_red "" "$suite_lbl failed '$*': $failed_ret"
  }

  test -n "$session" || sh_include finish
  exit $r
}

# Derive: U-S:tools/sh/parts/exec.sh
# Id: U-S:tools/ci/parts/exec.sh               ex:filetype=bash:colorcolumn=80:
