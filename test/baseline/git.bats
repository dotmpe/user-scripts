#!/usr/bin/env bats

load ../init
base='baseline:git'

setup()
{
   init && . $BATS_CWD/tools/sh/init.sh && load assert
}


@test "$base: git describe" {

  TODO '`git describe` fails in checkout with no tags'
}
