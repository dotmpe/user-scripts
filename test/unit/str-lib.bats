#!/usr/bin/env bats

base=str.lib
load ../init

setup()
{
  init &&
  load assert extra &&
  tmpd &&
  diag "$BATS_TEST_NUMBER. Tmp-Dir: $tmpd ($BATS_TEST_DESCRIPTION)"
}

teardown()
{
  cd "$BATS_CWD"
  # remove tmpdir for clean tests
  test -n "$BATS_ERROR_STATUS" || rm -rf "$tmpd"
}


@test "${base}: mkid" {
  skip TODO
}

@test "${base}: mkvid" {
  skip TODO
}

@test "${base}: mkcid" {
  skip TODO
}

@test "${base}: fnmatch" {
  skip TODO
}

@test "${base}: strip-last-nchars" {
  skip TODO
}
