#!/usr/bin/env bash
#
# Run project tooling

usage()
{
  echo 'Usage:'
  echo '  ./.build.sh <function name>'
  echo ''
  echo 'Functions are defined in script file and libs. Override or refer to
${_ENV:='"$_ENV"'} environment file for initial source. '
}
usage-fail() { usage && exit 2; }


init()
{
  assert_nonzero "$@" || set -- all
  ./tools/sh/parts/init.sh "$@" || return

  $LOG info "" "Running final checks..."
  ./tools/sh/parts/init.sh "default" >/dev/null
}

# Re-run init-checks (TODO or run if not yet run) and run over check part of
# every test-suite.
check()
{
  ./tools/sh/parts/init.sh check && {
    print_green "" "sh:init: check OK" >&2
  } || {
    $LOG error "" "sh:init: check" "" 1 ; return 1; }

  run-test check && {
    print_green "" "test: check OK" >&2
  } || {
    $LOG error "" "test: check" "" 1; return 1; }

  print_green "" "build: check OK" >&2
}

baselines()
{
  negatives-precheck && test/base.sh all
}

manual ()
{
  lib_require u_s-man || return
  build_manuals
  print_green "" "build OK" >&2
}

run-test()
{
  assert_nonzero "$@" || set -- all
  {
    print_yellow "" "build: run-test Starting '$*'... "
    test/base.sh "$@" || return
    test/lint.sh "$@" || return
    test/unit.sh "$@" || return
    test/bm.sh "$@" || return
    test/spec.sh "$@" || return
    print_green "" "build: run-test '$*' OK"
  } >&2
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

run-negative()
{
	set -- test/baseline/bats-negative.tap
	# Build test report and discard return-status since we invert check
  $package_build_tool "$1" || true
	# Match on any success; not any failure
	grep '^OK\ ' "$1" && false || true
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


init_sh_libs="script redo build" . "${_ENV:=tools/main/env.sh}"
$LOG "info" "" "Started sh env" "$_ENV"
main_ "run" "$@"
