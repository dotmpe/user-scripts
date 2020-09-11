#!/usr/bin/env bash
# Created: 2018-11-14

manual ()
{
  lib_require u_s-man || return
  build_manuals
  print_green "" "build OK" >&2
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
