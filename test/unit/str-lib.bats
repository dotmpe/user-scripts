#!/usr/bin/env bats

base=str.lib
load ../init

setup()
{
  init &&
  load ../assert &&
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
}

@test "${base}: mkvid" {
}

@test "${base}: mkcid" {
}

@test "${base}: fnmatch" {
}

@test "${base}: strip-last-nchars" {
}
