#!/usr/bin/env bats

load ../init
base='baseline-3:bats'

setup()
{
  init 0 0
}


@test "$base: vanilla shell; 'run' sets '\$status' and '\$lines'" {

  run true
  test ${status} -eq 0
  test -z "${lines}"

  run false
  test ${status} -ne 0
  test -z "${lines}"
}

@test "$base: assert lib (ztombol bats-assert)" {

  load assert || stdfail "No assert lib"

  run true
  assert_success
  assert_output ""

  run false
  assert_failure
  assert_output ""
}

@test "$base: helper lib (I)" {

  load extra
  load stdtest

  run true
  test_ok_empty
}

@test "$base: helper lib (II)" {

  load extra
  load stdtest

  run false
  test_nok_empty || stdfail

  run echo 123
  { test_ok_nonempty 1 && test_lines "123"
  } || stdfail
}
