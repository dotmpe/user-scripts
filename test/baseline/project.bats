#!/usr/bin/env bats

setup()
{
  export LOG=$PWD/tools/sh/log.sh
  export CS=dark
}


@test "init.sh setup" {

  . ./tools/sh/init.sh
}

@test "u-s run" {

  ./bin/u-s help
}
