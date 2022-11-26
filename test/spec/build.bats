#!/usr/bin/env bats

base=build
load ../init

setup ()
{
  init &&
  load assert extra stdtest
}

@test "$base-which: Baseline" {
  
  run build-which \&symbol
  test_ok_nonempty || stdfail 1

  run build-which \&symbol:key:\*
  test_ok_nonempty || stdfail 2
}
