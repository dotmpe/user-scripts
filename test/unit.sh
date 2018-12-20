#!/usr/bin/env bash
#
# Component unit-tests </doc/dev/ci>

usage()
{
  echo 'Usage:'
  echo '  test/unit.sh <function name>'
}
usage-fail() { usage && exit 2; }


# Groups

check()
{
  print_yellow "" "unit: check scripts..." >&2
  bats -c test/unit/*.bats >/dev/null
}

all()
{
  print_yellow "" "unit: all scripts..." >&2

  # FIXME: rebuild TAP repors based on changed prereq. only

  type lib_load >/dev/null 2>&1 || . "$script_util/init.sh"
  lib_load build
  lib_init

  build_tests bats tap test/unit/*.bats | while read -r tap
  do
    build $tap || true
  done

  grep -q '^NOT OK\ ' test/unit/*.tap && false || true
}


# Main

. "${TEST_ENV:=tools/ci/env.sh}"

main_test_ "$(basename "$0" .sh)" "$@"
