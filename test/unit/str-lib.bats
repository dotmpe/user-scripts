#!/usr/bin/env bats

base=str.lib
load ../init

setup()
{
  init &&
  load stdtest assert extra
  #tmpd &&
  #diag "$BATS_TEST_NUMBER. Tmp-Dir: $tmpd ($BATS_TEST_DESCRIPTION)"
}

teardown()
{
  cd "$BATS_CWD"
  # remove tmpdir for clean tests
  #test -n "$BATS_ERROR_STATUS" || rm -rf "$tmpd"
}


@test "${base}: str-sid" {

  id=$(str_sid "1+2/3|4-a^b\\c_f;e:x@y!z~")
  { test $? -eq 0 &&
    test -n "$id" &&
    assert_equal "$id" '1-2/3-4-a-b\c_f-e:x-y-z-'
  } || stdfail 1
}

@test "${base}: str-id" {
  skip TODO
}

@test "${base}: str-word" {
  skip TODO
}

@test "${base}: fnmatch" {
  skip TODO
}

@test "${base}: strip-last-nchars" {
  skip TODO
}
