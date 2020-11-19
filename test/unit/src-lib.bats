#!/usr/bin/env bats

load ../init
base=src.lib

setup()
{
  init && lib_load src
}


@test "$base: truncate_trailing_lines: " {

  skip FIXME truncate_trailing_lines
  echo
  tmpd
  out=$tmpd/truncate_trailing_lines
  printf "1\n2\n3\n4" >$out
  test -s "$out"
  ll="$(truncate_trailing_lines $out 1)"
  test -n "$ll"
  test "$ll" = "4"
}


@test "$base: file_insert_at" {
  skip TODO
}
