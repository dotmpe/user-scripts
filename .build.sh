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

# Re-run init-checks (TODO or run if not yet run) and run over check part of
# every test-suite.
check()
{
  ./.init.sh check && run-test check && echo "build: check OK" >&2
}

baselines()
{
  negatives-precheck && test/base.sh all
}

build()
{
  false
}

run-test()
{
  test -n "$1" || set -- all

  test/base.sh "$@" &&
  test/lint.sh "$@" &&
  test/unit.sh "$@" &&
  test/bm.sh "$@" &&
  test/spec.sh "$@" && echo "build: run-test '$*' OK" >&2
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

bats-negative()
{
	bats test/baseline/bats-negative.bats
}

negatives-precheck()
{
	bats-negative && false || true
}

pack()
{
  false
}

dist()
{
  false
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
