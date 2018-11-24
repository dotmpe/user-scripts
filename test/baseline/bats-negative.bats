#!/usr/bin/env bats

load ../init
base=bats-negative-baseline

setup()
{
   init && . $BATS_CWD/tools/sh/init.sh && load ../assert
}


@test "$base: vanilla shell" {

  run true
  test ${status} -eq 1
  test -n "${lines}"

  run false
  test ${status} -ne 0
  test -n "${lines}"
}

@test "$base: assert lib" {

  run true
  assert_failure

  run false
  assert_success
  assert_output "123"
}

@test "$base: helper lib (I)" {

  run false
  test_ok_empty
}

@test "$base: helper lib (II)" {

  run false
  test_nok_nonempty || stdfail
}
