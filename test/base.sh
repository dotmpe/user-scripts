#!/usr/bin/env bash
#
# Baseline descriobes third-party components, dependencies, host.
# For host/env prerequisites and checks see init and init-checks targets.

# Usage:
#   ./base.sh <function name>

set -o pipefail
set -o errexit


# Groups

check()
{
  true
}

all()
{
  default_test_run bats tap test/*-baseline.bats
}

default()
{
  all
}

test -n "$1" || set -- default

"$@"
