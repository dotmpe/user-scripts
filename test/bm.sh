#!/usr/bin/env bash
#
# Additional test-runs with the intend to generate and collection further
# profile information

usage()
{
  echo 'Usage:'
  echo '  test/bm.sh <function name>'
}
usage-fail() { usage && exit 2; }


# Groups

check()
{
  print_yellow "" "benchmarks: check scripts..." >&2
  true
}

all()
{
  print_yellow "" "benchmarks: all scripts..." >&2
  true
}

default()
{
  all
}


# Main

. "${TEST_ENV:=tools/ci/env.sh}"

main_test_ "$(basename -- "$0" .sh)" "$@"

# Derive: tools/sh/parts/init.sh
