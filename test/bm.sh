#!/usr/bin/env bash
#
# Additional test-runs with the intend to generate and collection further
# profile information
#
# Usage:
#   ./bm.sh <function name>

set -o pipefail
set -o errexit


# Groups

check()
{
  true
}

all()
{
  true
}

default()
{
  all
}

test -n "$1" || set -- default

"$@"
