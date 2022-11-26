#!/usr/bin/env bats

base=build.lib
load ../init

setup()
{
  init && lib_load build
}

@test "$base: foo" {
  true
}
