#!/usr/bin/env bats

load ../init
base=bats-negative-baseline

setup()
{
  init 0 0
}


@test "$base: vanilla shell" {

  run true
  test ${status} -eq 0
  test -z "${lines}"

  run false
  test ${status} -ne 0
  test -z "${lines}"
}

@test "$base: assert lib" {

  load assert

  run true
  assert_success

  run false
  assert_failure

  run echo 123
  assert_output "123"
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
