#!/usr/bin/env bats

load ../init
base='baseline-1:log'


@test "$base: LOG (harnassed)" {

  load ../helper/stdtest
  load ../helper/extra

  export DEBUG= verbosity=5
  LOG=tools/sh/log.sh

  run $LOG "info" "" "Test" "" 0
  test $status -eq 0
  test -z "${lines[*]}"

  run $LOG "info" "" "Test 2" "" 4
  test $status -eq 4
  test -z "${lines[*]}"

  run $LOG "notice" "" "Test 3" "" 0
  test $status -eq 0
  test -n "${lines[*]}"
  fnmatch "*Test 3*" "${lines[*]}" || stdfail "Expected LOG output"
}

@test "$base: another simple shell baseline check for logging sys" {

  load_init_bats
  load ../helper/stdtest

  skip "FIXME: logger testing, test @Matrix"

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
}
