#!/usr/bin/env bash
#
# System, integration and acceptance tests </doc/dev/ci>
#
# Usage:
#   ./lint.sh <function name>

set -o pipefail
set -o errexit


test -n "$scriptpath" || exit 5
. $scriptpath/tools/sh/init.sh


# Groups

check()
{
  bats -c test/spec/*.bats >/dev/null
}

all()
{
  bats test/spec/*.bats
}

test -n "$1" || set -- all

"$@"
