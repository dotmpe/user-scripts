#!/usr/bin/env bats

base=shell-baseline


@test "$base: LOG (normal mode, no debug, verbosity < 7)" {

  run $LOG "info" "" "Tester de test" "" 0
  test $status -eq 0 && test -z "${lines[*]}"

  test -z "$DEBUG"

  test -z "$verbosity" || {
    test $verbosity -lt 7
  }

  #skip FIXME

  # Again, no harnass.
  # XXX: $LOG "info" "" "Tester de test" "" 0
}

@test "$base: another simple shell baseline check for logging sys" {

  #_r() { LOG=logger_stderr BASH_ENV=tools/sh/env.sh \
  #  $SHELL -c 'echo $LOG'; }; run _r

  #test "${lines[*]}" = "logger_stderr" || {
  #  echo "${lines[*]}" >&2 && false
  #}

  LOG=logger_stderr BASH_ENV=tools/sh/env.sh \
    $SHELL -c '$LOG "info" "" "Tester de test" "" 0'
}
