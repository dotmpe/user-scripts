#!/bin/sh

# User-script lib to deal with Git


git_version()
{
  git describe --always
}

u_s_version() #
{
  test $# -eq 0 || return 99
  test "$PWD" = "$U_S" || cd "$U_S"
  git_version
}

git_update_from_repo() # Repo-Id
{
  test $# -le 1 || return 99
  test $# -gt 0 || set -- ""
  test -n "$1" || set -- "${U_S_REPO_ID}"
  trueish "$offline" && return 1
  git fetch -q "$1" || return
  git fetch -q --tags "$1"
}

git_reset_hard() # [Repo-Release] [Repo-Id] [Repo-URL]
{
  test $# -le 2 || return 99

  while test $# -lt 3 ; do set -- "$@" "" ; done

  local repo_rev= repo_url= repo_id=
  u_s_devline_args "$2" "$3" "$1" || return

  trueish "$offline" || { git_update_from_repo "$2" || return $?; }
  git reset -q --hard $2/$1
}

u_s_repo_args() # Repo-Id [Repo-Url]
{
  test $# -le 2 || return 99

  test $# -gt 0 || set -- ""
  test $# -gt 1 || set -- "$1" ""

  test -n "$1" || set -- "${U_S_REPO_ID}" "$2"
  test -n "$2" || set -- "$1" "${U_S_REPO_URL}"
  test -n "$1" -a -n "$2" || return 99

  # XXX: make sure at least internal hardcoded repo-id/Url match
  test "${U_S_REPO_ID}" = "$1" -o "${U_S_REPO_URL}" = "$2" && {
    test "${U_S_REPO_ID}" = "$1" -a "${U_S_REPO_URL}" = "$2" || return 98;
  }

  repo_id="$1" repo_url="$2"
}

u_s_devline_args() # Repo-Id [Repo-Url] [Repo-Revision]
{
  test $# -le 3 || return 99

  while test $# -lt 3 ; do set -- "$@" "" ; done

  test -n "$2" -o -z "$1" || {
    set -- "$1" "$(git config --get remote.$1.url || return 97 )" "$3"
  }

  test -n "$3" || set -- "$1" "$2" "${U_S_RELEASE}"
  test -n "$3" || return 99

  repo_rev="$3"
  u_s_repo_args "$1" "$2"
}
