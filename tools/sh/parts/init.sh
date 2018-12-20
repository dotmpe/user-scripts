#!/usr/bin/env bash
#
# Provisioning and project init helpers

usage()
{
  echo 'Usage:'
  echo '  ./tools/sh/parts/init.sh <function name>'
}
usage-fail() { usage && exit 2; }


init-git()
{
  test -x "$(which git)" || return
  init-git-hooks || return
  init-git-submodules || return
}

init-git-hooks()
{
  test -e .git/hooks/pre-commit || {
    rm .git/hooks/pre-commit || true
    ln -s ../../tools/git/hooks/pre-commit.sh .git/hooks/pre-commit || return
  }
}

init-git-submodules()
{
  test -e .git/modules || {
    git submodule update --init || return
  }
}

check-git()
{
  test -x "$(which git)" || return
  test -h .git/hooks/pre-commit &&
  test -d .git/modules
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
  test -x "$(which redo)" || return
  redo -h 2>/dev/null || r=$?
  test "$r" = "97" || init-err "redo:-h:err:$r"
  # Must not be in parent dir, or targets become mixed with other projects, and harder to track
  # FIXME: only available after run; chicken-and-the-egg problem
  #test -d .redo/ || init-err "redo:repo"
}

init-bats()
{
  $LOG info "" "Installing bats..."

  : "${BATS_VERSION:=master}"
  : "${BATS_REPO:="https://github.com/bats-core/bats-core.git"}"
  : "${BATS_PREFIX:=$VND_GH_SRC/bats-core/bats-core}"

  test -d $BATS_PREFIX/.git || {

    mkdir -vp "$(dirname "$BATS_PREFIX")"
    test ! -e $BATS_PREFIX || {
      rm -rf $BATS_PREFIX || return
    }

    git clone "$BATS_REPO" $BATS_PREFIX || return $?
  }

  (
    cd $BATS_PREFIX &&
    git checkout "$BATS_VERSION" -- && ./install.sh $PREFIX
  )
}

check-bats()
{
  bats --version >/dev/null
}

check-github-release()
{
  github-release --version >/dev/null
}

init-github-release()
{
  go get github.com/aktau/github-release
}

init-err()
{
  $LOG error "" "failed during init" "$*"
  print_red "sh:init" "failed at '$*'" >&2
  exit 1
}

check()
{
  default >/dev/null || init-err default

  git describe >/dev/null ||
    init-err "git describe: CWD should be GIT checkout and have tags in repo"
}


# Groups

default()
{
  check-git || init-err git
  check-basher || init-err basher
  check-bats || init-err bats
  # XXX: check-redo || init-err redo
  check-github-release || init-err github-release
  test -n "$VND_GH_SRC" || init-err VND-GH-SRC
  for helper in bats-assert bats-file bats-support
  do
    test -d $VND_GH_SRC/ztombol/$helper || init-err $helper
  done
}

all()
{
  init-git || init-err git $?

  # XXX which github-release >/dev/null || {
  test -x "$(which github-release)" || {
    init-github-release || init-err github-release $?
  }
  test -x "$(which basher)" || {
    init-basher || init-err basher $?
  }
  test -x "$(which redo)" || {
    init-redo || init-err redo $?
  }

  BATS_VERSION_="$(bats --version)"
  { test -x "$(which bats)" && fnmatch "Bats 1.1.*" "$BATS_VERSION_"
  } || {
    $LOG warn "" "Found $BATS_VERSION_, getting 1.1..."
    PREFIX=$HOME/.local init-bats || return
  }

  #reset-cache
  #rm -rf $VND_GH_SRC/ztombol || true

  for helper in bats-assert bats-file bats-support
  do
    test -d $VND_GH_SRC/ztombol/$helper || {
      mkdir -vp "$VND_GH_SRC/ztombol"
      $LOG info "" "Adding test-helper $helper..."
      git clone --depth 15 \
        https://github.com/ztombol/$helper.git $VND_GH_SRC/ztombol/$helper ||
        return
    }
  done
}


# Main

type req_subcmd >/dev/null 2>&1 || . "${TEST_ENV:=tools/ci/env.sh}"
# Fallback func-name to init namespace to avoid overlap with builtin names
main_ "init" "$@"
