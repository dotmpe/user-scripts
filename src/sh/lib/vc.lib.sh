#!/bin/sh


vc_lib__init()
{
  test "${vc_lib_init-}" = "0" && return
  test -n "${INIT_LOG-}" || return 109
  $INIT_LOG debug "" "Initialized vc.lib" "$0"
}

# Given COPY src and trgt file from user-conf repo,
# see if target path is of a known version for src-path in repo,
# and that its the currently checked out version.
vc_gitdiff ()
{
  test -n "${1-}" || err "vc-gitdiff expected src" 98
  test -n "${2-}" || err "vc-gitdiff expected trgt" 98
  test -z "${3-}" || err "vc-gitdiff surplus arguments: '$3'" 98
  test -n "${GITDIR-}" || err "vc-gitdiff expected GITDIR env" 1
  test -d "$GITDIR" || err "vc-gitdiff GITDIR env is not a dir" 1

  target_sha1="$(git hash-object "$2")"
  co_path="$(cd $GITDIR;git rev-list --objects --all | grep "^$target_sha1" | cut -d ' ' -f 2)"
  test -n "$co_path" -a "$1" = "$GITDIR/$co_path" && {
    # known state, file can be safely replaced
    test "$target_sha1" = "$(git hash-object "$1")" \
      && return 0 \
      || {
        return 1
      }
  } || {
    return 2
  }
}

vc_gitdir()
{
  test $# -le 1 || err "vc-gitdir surplus arguments" 1
  test -n "${1-}" || set -- "."
  test -d "$1" || err "vc-gitdir expected dir argument" 98

  test -d "$1/.git" && {
    echo "$1/.git"
  } || {
    test "$1" = "." || cd $1 || return
    git rev-parse --git-dir 2>/dev/null
  }
}

# See if path is in GIT checkout
vc_isgit()
{
  test -e "${1-}" || err "vc-isgit expected path argument" 98
  test -d "$1" || {
    set -- "$(dirname "$1")"
  }
  while test "$1" != "/"
  do
    test -e $1/.git && {
      echo "$1"
      return
    }
    set -- "$(dirname "$1")"
  done
  return 1
}

vc_isscmdir()
{
  test -n "${1-}" || set -- "."
  test -d "$1" || error "vc-isscmdir expected dir argument: '$1'" 1
  vc_isgit "$1" && return
  return 1
}

vc_remote()
{
  test -n "$1" || set -- "." "origin"
  test -d "$1" || error "vc-remote expected dir argument" 1
  test -n "$2" || error "vc-remote expected remote name" 1
  test -z "$3" || error "vc-remote surplus arguments" 1

  local pwd=$PWD
  cd "$1"
  vc_remote_$scm "$2"
  cd "$pwd"
}

vc_remote_git()
{
  git config --get remote.$1.url
}

# XXX: unused
vc_remote_hg()
{
  hg paths "$1"
}
