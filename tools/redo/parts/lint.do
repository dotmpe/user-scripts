#!/usr/bin/env bash
# Created: 2018-10-17
# TODO: lint check
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
#
