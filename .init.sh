#!/usr/bin/env bash
#
# Provisining and project init helpers
#
# Usage:
#   .init.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

init-git()
{
  test -e .git/hooks/pre-commit || {
    ln -s ../../.build/pre-commit.sh .git/hooks/pre-commit || return
  }
  test -e .git/modules || {
    git submodule update --init || return
  }
}

check-git()
{
  test -h .git/hooks/pre-commit &&
  test -d .git/modules
}

check-redo()
{
  # Must not be in parent dir, or targets become mixed with other projects, and harder to track
  test -d .redo/
}


# Groups

default()
{
  check-git &&
  check-redo
}

all()
{
  init-git &&
  check-git
}


# XXX: Map to namespace to avoid overlap with builtin names
act="$1" ;
case "$1" in git ) shift 1 ; set -- init-$act "$@" ;; esac
unset act

test -n "$1" || set -- default

"$@"
