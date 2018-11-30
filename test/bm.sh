#!/usr/bin/env bash
#
# Additional test-runs with the intend to generate and collection further
# profile information
#
# Usage:
#   ./bm.sh <function name>

set -o pipefail
set -o errexit


. ./tools/sh/init.sh


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

test -n "$1" || set -- default

"$@"
