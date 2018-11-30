#!/usr/bin/env bats

base=realpath-baseline
load ../init

setup()
{
  init
}


@test "realpath baseline --help" {

  # realpath --help || realpath -h || realpath --version || realpath -V
  run realpath --help
# XXX: simple older vs grealpath; { test_ok_nonempty && test_lines "Usage: realpath \[OPTION\]... FILE..."
  { test_ok_nonempty && test_lines "*Usage:*"
# " realpath [-s|--strip] [-z|--zero] filename ..." \
# " realpath -v|--version"
  } || stdfail "--help"

}


@test "realpath baseline --relative-base is present" {

  skip "Using simple realpath on Travis CI now"
  run realpath --help
  { test_ok_nonempty && test_lines \
    "* --relative-base=DIR *"
  } || stdfail "--relative-base"

}


@test "realpath baseline --relative-to is present" {

  skip "Using simple realpath on Travis CI now"
  run realpath --help
  { test_ok_nonempty && test_lines \
    "* --relative-to=DIR *"
  } || stdfail "--relative-to"

}
