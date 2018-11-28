#!/usr/bin/env bats

load ../init
base=bats-negative-baseline

setup()
{
   init
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
  assert_output ""

  run false
  assert_failure
  assert_output ""
}
