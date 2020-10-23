#!/usr/bin/env bats

load ../init
base='baseline:git'

setup()
{
   true #init && . $BATS_CWD/tools/sh/init.sh && load assert
}


@test "$base: git describe" {

  skip '`git describe` fails in checkout with no tags'
  # TODO '`git describe` fails in checkout with no tags'
}
