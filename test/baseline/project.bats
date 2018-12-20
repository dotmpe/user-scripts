#!/usr/bin/env bats

base=project-baseline


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


@test "$base: tools/sh/log" {

  load ../init
  load extra
  load stdtest
  LOG=tools/sh/log.sh

  run $LOG tag1 tag2 msg tag3 0
  { test_ok_nonempty 1 && test_lines ' msg <tag3>'
  } || stdfail "1.A. '${lines[0]}'"

  run $LOG tag1 tag2 msg tag3 1
  { test_nok_nonempty 1 && test_lines " msg <tag3>"
  } || stdfail 1.B.

  run $LOG ok "tag1 tag2" "A longer message" "tag3 tag4"
  { test_ok_nonempty 1 &&
    test_lines '\[tag1 tag2] OK: A longer message <tag3 tag4>'
  } || stdfail "1.A.2 '${lines[0]}'"

  run $LOG tag1 tag2 msg tag3 0
  test_ok_nonempty || stdfail 2.
}
