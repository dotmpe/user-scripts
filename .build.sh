#!/usr/bin/env bash
#
# Run project tooling
#
# Usage:
#   ./.build.sh <function name>

set -o nounset
set -o pipefail
set -o errexit


init()
{
  test $# -gt 0 || set -- all

  ./.init.sh "$@" || false

  echo "Running final checks..." >&2
  ./.init.sh "default" >/dev/null
}

# Re-run init-checks (TODO or run if not yet run) and run over check part of
# every test-suite.
check()
{
  ./.init.sh check || return
  run-test check || return
  print_green "" "build: check OK" >&2
}

baselines()
{
  negatives-precheck ||
  test/base.sh all
}

build()
{
  false
}

run-test()
{
  test $# -gt 0 || set -- all

  test/base.sh "$@" || return
  test/lint.sh "$@" || return
  test/unit.sh "$@" || return
  test/bm.sh "$@" || return
  test/spec.sh "$@" || return
  print_green "" "build: run-test '$*' OK" >&2
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
	set -- test/baseline/bats-negative.tap
	# Build test report and discard return-status since we invert check
	$package_build_tool "$1" || true
	# Match on any success; not any failure; return un-inverted status
	grep '^OK\ ' "$1"
}

# Run 'negatives' from baseline suite. Expect only error states or abort
negatives-precheck()
{
  $LOG info build "Starting negatives precheck"
	bats-negative && {
    $LOG error build "Negative test(s) check unexpectedly succeeded" 1
    return 1
  }
  $LOG ok build "Negative checks passed: all failed as expected."
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
  init && check && build && run-test && pack
}


test $# -gt 0 || set -- default

# XXX: Map to namespace to avoid overlap with builtin names
act="$1" ;
case "$1" in test ) shift 1 ; set -- run-$act "$@" ;; esac
unset act

type fnmatch >/dev/null 2>&1 || . "${BASH_ENV:-tools/ci/env.sh}"

"$@"
