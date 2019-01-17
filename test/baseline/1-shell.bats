#!/usr/bin/env bats

load ../init
base='baseline-1:shell'

setup()
{
  init
}


@test "$base: LOG (normal mode, no debug, verbosity < 7)" {

  export DEBUG= verbosity=4

  run $LOG "info" "" "Tester de test" "" 0
  test $status -eq 0 && test -z "${lines[*]}"

  # Again, no harnass.
  # XXX: $LOG "info" "" "Tester de test" "" 0
}

@test "$base: another simple shell baseline check for logging sys" {

  #load extra
  load stdtest

  skip "FIXME: logger testing"

  #_r() { LOG=logger_stderr BASH_ENV=tools/sh/env.sh \
  #  $SHELL -c 'echo $LOG'; }; run _r

  #test "${lines[*]}" = "logger_stderr" || {
  #  echo "${lines[*]}" >&2 && false
  #}

  U_S=$HOME/project/user-script
  for verbosity in "" 7 6 5 4 3 2 1
  do
    for LOG in "" logger_stderr "$U_S/tools/sh/log.sh"
    do
      for SCRIPTPATH in "" "$SCRIPTPATH"
      do
        for level in debug info note warn error emerg crit
        do
          _r() {
            LOG=$LOG verbosity=$verbosity SCRIPTPATH="$SCRIPTPATH" \
            BASH_ENV=tools/sh/env.sh \
              $SHELL -c '$LOG "$level" "" "Test de $level" "" 0'
          }; run _r
          { test $status -eq 0
          } || diag "Failed (v:$v LOG:$LOG lvl:$level S-P:$SCRIPTPATH)"
        done
      done
    done
  done

  stdfail "FIXME: @Matrix"
}
