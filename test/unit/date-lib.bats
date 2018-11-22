#!/usr/bin/env bats

base=date.lib
load ../init

setup()
{
  init && lib_load date &&
  tmpd && cd $tmpd
}

teardown()
{
  cd $BATS_CWD && rm -rf "$tmpd"
}


@test "${base}: timestamp2touch ( FILE | DATESTR ) " {

  year=$(date +%y) ; month=$(date +%m) ; day=$(date +%d)

  run timestamp2touch
  { test_ok_nonempty 1 &&
    fnmatch "$year$month$day[0-9][0-9][0-9][0-9].[0-9][0-9]" "${lines[0]}"
  } || stdfail 1.

  run timestamp2touch "1970-01-01T00:00:01Z"
  { test_ok_nonempty 1 &&
    test "7001010100.01" = "${lines[0]}"
  } || stdfail 2.

  run timestamp2touch "1970-01-01T01:01:01+0200"
  { test_ok_nonempty 1 &&
    test "7001010001.01" = "${lines[0]}"
  } || stdfail 3.

}

@test "${base}: touch-ts FILE [ TIMESTAMP | FILE ]" {


  run touch -t 7001010100.01 foo
  mtime=$(filemtime foo)
  { test_ok_empty &&
    test -e foo &&
    test $mtime -eq 1
  } || stdfail "1. $mtime"


  run touch_ts @1 foo
  mtime=$(filemtime foo)
  { test_ok_empty &&
    test -e foo &&
    test $mtime -eq 1
  } || stdfail "2. $mtime"


  run touch_ts "1970-01-01T00:00:01Z" foo
  mtime=$(filemtime foo)
  { test_ok_empty &&
    test -e foo &&
    test $mtime -eq 1
  } || stdfail "3. $mtime"

}

@test "${base}: older-than FILE SECONDS" {


  touch_ts @1 foo
  run older_than foo $_1MIN
  { test_ok_empty ; } || stdfail
  run older_than foo $_1YEAR
  { test_ok_empty ; } || stdfail

  touch -t $(timestamp2touch) foo
  run older_than foo $_1MIN
  { test_nok_empty ; } || stdfail
  run older_than foo $_1YEAR
  { test_nok_empty ; } || stdfail

}

@test "${base}: newer-than FILE SECONDS " {


  touch_ts @1 foo
  run newer_than foo $_1MIN
  { test_nok_empty ; } || stdfail
  run newer_than foo $_1YEAR
  { test_nok_empty ; } || stdfail

  touch -t $(timestamp2touch) foo
  run newer_than foo $_1MIN
  { test_ok_empty ; } || stdfail
  run newer_than foo $_1YEAR
  { test_ok_empty ; } || stdfail

}
