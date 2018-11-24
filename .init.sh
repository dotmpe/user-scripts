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
  which git || return
  test -e .git/hooks/pre-commit || {
    ln -s ../../.build/pre-commit.sh .git/hooks/pre-commit || return
  }
  test -e .git/modules || {
    git submodule update --init || return
  }
}

check-git()
{
  test -x "$(which git)" || return
  test -h .git/hooks/pre-commit && test -d .git/modules
}

init-basher()
{
  git clone https://github.com/basherpm/basher.git ~/.basher/
}

check-basher()
{
  basher help >/dev/null
}

init-redo()
{
  basher install apenwarr/redo
}

check-redo()
{
  local r=''
  redo -h || r=$?
  test "$r" = "97" || init-err "redo:-h:err:$r"
  # Must not be in parent dir, or targets become mixed with other projects, and harder to track
  # FIXME: only available after run; chicken-and-the-egg problem
  #test -d .redo/ || init-err "redo:repo"
}

init-bats()
{
  test -n "$SRC_PREFIX" -a -n "$BATS_REPO" -a -n "$BATS_VERSION" || return
  echo "Installing bats" >&2
  test -d $SRC_PREFIX/local/ || mkdir $SRC_PREFIX/local/
  test -d $SRC_PREFIX/local/bats || {
    git clone $BATS_REPO $SRC_PREFIX/local/bats || return $?
  }
  (
    cd $SRC_PREFIX/local/bats &&
    git checkout $BATS_VERSION &&
    ./install.sh $PREFIX
  )
}

check-bats()
{
  bats --version >/dev/null
}

init-src()
{
  test -n "$1" -a -n "$2" -a -d "$2"  -a -w "$2" || return
  local repo='' group=''
  repo="$(basename "$1" .git)"
  group="$(basename "$(dirname "$1")")"

  test -d "$2/$group" || mkdir -vp "$2/$group"
  git clone "$1" "$2/$group/$repo" && echo "Clone to $group/$repo OK" >&2
}

init-err()
{
  echo "init: Error $*" >&2
  exit 1
}

check()
{
  default >/dev/null || init-err default
  git describe >/dev/null || init-err "git describe: CWD should be GIT checkout and have tags in repo"
}


# Groups

default()
{
  check-git || init-err git
  check-basher || init-err basher
  check-bats || init-err bats
  check-redo || init-err redo
  test -n "$VND_GH_SRC" || init-err VND-GH-SRC
  for helper in bats-assert bats-file bats-support
  do
    test -d $VND_GH_SRC/ztombol/$helper || init-err $helper
  done
}

all()
{
  init-git || return
  which basher || { init-basher || return; }
  which redo || { init-redo || return; }
  which bats || { init-bats || return; }

  test -n "$VND_GH_SRC" || return
  for helper in bats-assert bats-file bats-support
  do
    test -d $VND_GH_SRC/ztombol/$helper || {
      init-src https://github.com/ztombol/$helper.git $VND_GH_SRC/ || return
    }
  done

  echo "Running final checks..." >&2
  default >/dev/null
}


# XXX: Map to namespace to avoid overlap with builtin names
act="$1" ;
case "$1" in git ) shift 1 ; set -- init-$act "$@" ;; esac
unset act

test -n "$1" || set -- default

"$@"
