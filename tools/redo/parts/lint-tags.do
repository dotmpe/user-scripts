#!/usr/bin/env bash
# Created: 2018-10-17
# TODO: lint check
lint-tags()
{
  test -z "$*" && {
    # TODO: forbid only one tag... setup degrees of tags allowed per release

    git grep '\(XXX\|FIXME\|TODO\): .*\<no-commit\>' "$@" && return 1 || true
  } || {

    git grep '\(XXX\|FIXME\|TODO\):' "$@" && return 1 || true
  }
}

git ls '*.sh' | {
  while read -r x
  do
    lint-tags "$x" || {
      fail=$?
      echo "Failed at $x E$fail" >&2
    }
  done
  return ${fail:-0}
}

#
