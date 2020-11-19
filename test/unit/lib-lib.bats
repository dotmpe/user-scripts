#!/usr/bin/env bats

base=lib.lib
load ../init



@test "${base}: lib_load A/B" {

  init 1 0
  load stdtest

  run lib_load sys
  { test_ok_empty
  } || stdfail 1.

  run lib_load
  { test_nok_empty
  } || stdfail 2.
}

@test "${base}: lib_load sys" {

  test -z "$sys_lib_loaded"
  init 1 0
  test -z "$sys_lib_loaded"
  load stdtest

  { test -z "$sys_lib_loaded"
  } || stdfail 1.

  lib_load sys
  { test -n "$sys_lib_loaded"
  } || stdfail 2.
}
