#!/usr/bin/env bash
#
# Tools to maintain coding style standards </doc/dev/ci>

usage()
{
  echo 'Usage:'
  echo '  test/lint.sh <function name>'
}
usage-fail() { usage && exit 2; }


lint-bats()
{
  test -n "$*" || set -- test/*.bats
  test "$1" != "test/*.bats" || return 0
  # Count flag to load, parse but dont step tests.
  bats -c "$@" >/dev/null
}

lint-tags()
{
  test -z "$*" && {
    # TODO: forbid only one tag... setup degrees of tags allowed per release

    { git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' "$@" && return 1 || true
    } >&2
  } || {

    { git grep '\(XXX\|FIXME\|TODO\):' "$@" && return 1 || true
    } >&2
  }
}

# Groups

check()
{
  print_yellow "" "lint: check scripts..." >&2
  # TODO: lint markdown
  # TODO: lint sh-scripts
  # TODO: lint bash-scripts
  lint-bats &&
  lint-tags &&
  print_green "" "no lint identified!" >&2
}

all()
{
  check
}


# Main

. "${TEST_ENV:=tools/ci/env.sh}"

main_test_ "" "$@"
