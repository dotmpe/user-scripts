#!/usr/bin/env bats

base=realpath-baseline
load ../init

setup()
{
  init &&
  load ../assert
}


@test "realpath" {

  run realpath --help
  #{ test_ok_nonempty && test_lines
  { test_ok_empty
  } || stdfail
}
