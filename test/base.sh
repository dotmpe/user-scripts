#!/usr/bin/env bash
#
# Baseline descriobes third-party components, dependencies, host.
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

type req_subcmd >/dev/null 2>&1 || . "${TEST_ENV:=tools/ci/env.sh}"

main_test_ "$(basename "$0" .sh)" "$@"
