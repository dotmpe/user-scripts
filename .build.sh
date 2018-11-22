#!/usr/bin/env bash
#
# Run project tooling
#
# Usage:
#   ./.build.sh <function name>

set -o pipefail
set -o errexit


init()
{
  test -n "$1" || set -- all

  ./.init.sh "$@"
}

init-checks()
{
  bash --version &&
  git --version &&
  # FIXME: redo --version &&
  make --version &&

  ./.init.sh check-git
}

check()
{
  run-test check >&2
}

build()
{
  true
}

run-test()
{
  test -n "$1" || set -- all

  test/base.sh "$@" &&
  test/lint.sh "$@" &&
  test/unit.sh "$@" &&
  test/bm.sh "$@" &&
  test/spec.sh "$@"
}

clean()
{
  find ./ -iname '*.tap' -exec rm -v "{}" + # FIXME &&
  #{
  #  not_trueish "$clean_force" || {
  #    git clean -df && git clean -dfx */
  #  }
  #}
}


# Groups

default()
{
  init &&
  check
}

all()
{
  init && check && build && test && pack
}


# XXX: Map to namespace to avoid overlap with builtin names
act="$1" ;
case "$1" in test ) shift 1 ; set -- run-$act "$@" ;; esac
unset act

test -n "$1" || set -- default

"$@"
