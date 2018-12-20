#!/usr/bin/env bash
#
# Run project tooling

usage()
{
  echo 'Usage:'
  echo '  ./.build.sh <function name>'
}
usage-fail() { usage && exit 2; }


init()
{
  assert_nonzero "$@" || set -- all
  ./tools/sh/parts/init.sh "$@" || return

  $LOG info "" "Running final checks..." >&2
  ./tools/sh/parts/init.sh "default" >/dev/null
}

# Re-run init-checks (TODO or run if not yet run) and run over check part of
# every test-suite.
check()
{
  ./tools/sh/parts/init.sh check || {
    $LOG error "" "sh:init check" "" 1 ; return 1; }

  run-test check || {
    $LOG error "" "test: check" "" 1; return 1; }

  print_green "" "build: check OK" >&2
}

baselines()
{
  negatives-precheck || test/base.sh all
}

build()
{
  true
}

run-test()
{
  assert_nonzero "$@" || set -- all

  print_yellow "" "build: run-test Starting '$*'... " >&2
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
  true
}

dist()
{
  false
}


# Groups

default()
{
  init && check
}

all()
{
  init && check && build && run-test && pack
}


# Main

type req_subcmd >/dev/null 2>&1 || . "${TEST_ENV:=tools/ci/env.sh}"
# Fallback func-name to init namespace to avoid overlap with builtin names
main_ "run" "$@"
