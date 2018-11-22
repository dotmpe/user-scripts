#!/usr/bin/env bash
#
# Baseline descriobes third-party components, dependencies, host.
# For host/env prerequisites and checks see init and init-checks targets.

# Usage:
#   ./base.sh <function name>

set -o pipefail
set -o errexit


test -n "$scriptpath" || exit 5
. $scriptpath/tools/sh/init.sh

lib_load build


# Groups

check()
{
  bats -c test/baseline/*.bats >/dev/null
}

all()
{
  build_tests bats tap test/baseline/*.bats | while read -r tap
  do
    build $tap
  done
}

test -n "$1" || set -- all

"$@"
