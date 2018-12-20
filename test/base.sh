#!/usr/bin/env bash
#
# Baseline describes third-party components, dependencies, host.hk
# For host/env prerequisites and checks see init and init-checks targets.

usage()
{
  echo 'Usage:'
  echo '  test/base.sh <function name>'
}
usage-fail() { usage && exit 2; }


# Groups

check()
{
  print_yellow "" "baseline: check scripts..." >&2
  bats -c test/baseline/*.bats >/dev/null
}

all()
{
  print_yellow "" "baseline: all scripts..." >&2

  # FIXME: rebuild TAP repors based on changed prereq. only

  type lib_load >/dev/null 2>&1 || . "$script_util/init.sh"
  lib_load build
  lib_init

  build_tests bats tap test/baseline/*.bats | while read -r tap
  do
    echo "Building '$tap'..." >&2
    case "$tap" in
      # Test negatives separately (apply to test harnass themselves more than host env)
      *-negative.tap ) continue ;;
      redo* ) continue ;;
    esac

    build $tap || true
  done

  grep -q '^NOT OK\ ' test/baseline/*.tap && false || true
}


# Main

. "${TEST_ENV:=tools/ci/env.sh}"

main_test_ "$(basename "$0" .sh)" "$@"
