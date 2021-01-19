#!/usr/bin/env bats

base=date.lib
load ../init
init

setup()
{
  lib_load date &&
  load extra stdtest &&
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


  export TZ=UTC
  ts=7001010000.01
  run timestamp2touch "1970-01-01T00:00:01Z"
  { test_ok_nonempty 1 && test "$ts" = "${lines[0]}"
  } || stdfail 2.

  ts=6912312301.01
  run timestamp2touch "1970-01-01T01:01:01+0200"
  { test_ok_nonempty 1 && test "$ts" = "${lines[0]}"
  } || stdfail 3.

  test "${CIRCLECI:-}" = "true" -o "${SHIPPABLE:-}" = "true" &&
    skip FIXME: TZ not working as expected on CI

  export TZ=CET
  ts=7001010001.01
  run timestamp2touch "1970-01-01T01:01:01+0200"
  { test_ok_nonempty 1 && test "$ts" = "${lines[0]}"
  } || stdfail 4.

  ts=7001010100.01
  run timestamp2touch "1970-01-01T00:00:01Z"
  { test_ok_nonempty 1 && test "$ts" = "${lines[0]}"
  } || stdfail 5.
}

@test "${base}: touch-ts FILE [ TIMESTAMP | FILE ]" {

  test -z "${TRAVIS_JOB_NUMBER:-}" || skip "FIXME at travis"

  test "${CIRCLECI:-}" = "true" -o "${SHIPPABLE:-}" = "true" &&
    skip FIXME: TZ not working as expected on CI

  export TZ=CET

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

  test -z "${TRAVIS_JOB_NUMBER:-}" || skip "FIXME at travis"

  verbosity=4

  touch_ts @1 foo
  run older_than foo $_1MIN
  { test_ok_empty ; } || stdfail A.1
  run older_than foo $_1YEAR
  { test_ok_empty ; } || stdfail A.2

  touch -t $(timestamp2touch) foo
  run older_than foo $_1MIN
  { test_nok_empty ; } || stdfail B.1
  run older_than foo $_1YEAR
  { test_nok_empty ; } || stdfail B.2

}

@test "${base}: newer-than FILE SECONDS " {

  export verbosity=4

  touch_ts @1 foo
  run newer_than foo $_1MIN
  { test_nok_empty ; } || stdfail A.1
  run newer_than foo $_1YEAR
  { test_nok_empty ; } || stdfail A.2

  touch -t $(timestamp2touch) foo
  run newer_than foo $_1MIN
  { test_ok_empty ; } || stdfail B.1
  run newer_than foo $_1YEAR
  { test_ok_empty ; } || stdfail B.2

}
