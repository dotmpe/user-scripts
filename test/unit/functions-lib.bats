#!/usr/bin/env bats

base=functions.lib
load ../init

setup()
{
  init &&
  load stdtest &&
  lib_load sys src functions
}

@test "$base: list" {

  run functions_list "src/sh/lib/functions.lib.sh"
  { test_ok_nonempty 15 && \
    test_lines "functions_list() # *"
  } || stdfail
}
