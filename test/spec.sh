#!/usr/bin/env bash
#
# System, integration and acceptance tests </doc/dev/ci>

usage()
{
  echo 'Usage:'
  echo '  test/spec.sh <function name>'
}
usage-fail() { usage && exit 2; }


# Groups

check()
{
  print_yellow "" "spec: check scripts..." >&2
  bats -c test/spec/*.bats >/dev/null
}

all()
{
  print_yellow "" "spec: all scripts..." >&2
  bats test/spec/*.bats &&
  print_green "" "specs OK" >&2
}


# Main

. "${TEST_ENV:=tools/ci/env.sh}"

main_test_ "$(basename "$0" .sh)" "$@"
