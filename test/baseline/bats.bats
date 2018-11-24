#!/usr/bin/env bats

load ../init
base=bats-negative-baseline

setup()
{
   init && . $BATS_CWD/tools/sh/init.sh && load ../assert
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

  run true
  assert_success
  assert_output ""

  run false
  assert_failure
  assert_output ""
}
