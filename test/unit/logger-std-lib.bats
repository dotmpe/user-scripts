#!/usr/bin/env bats

base=logger-std.lib
load ../init

setup()
{
  init && lib_load logger-std
}

@test "$base: demo" {
  load stdtest

  run stderr_demo
  test_ok_nonempty || stdfail 1.
}
