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
  echo "baseline: check scripts..." >&2
  bats -c test/baseline/*.bats >/dev/null
}

all()
{
  echo "baseline: all scripts..." >&2
  build_tests bats tap test/baseline/*.bats | while read -r tap
  do
    echo "Building '$tap'..." >&2
    case "$tap" in
      # Test negatives separately (apply to test harnass themselves more than host env)
      *-negative.tap ) continue ;;
      redo* ) continue ;;
    esac
    build $tap
  done
}

test -n "$1" || set -- all

"$@"
