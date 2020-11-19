#!/usr/bin/env bats

load ../init
base='baseline:git'

setup()
{
   init 1 0 && load stdtest
}


@test "$base: git describe" {

  #skip '`git describe` fails in checkout with no tags'
  run git describe --always
  test_ok_nonempty || stdfail
}
