#!/bin/sh

# For use with basher-type install User-scripts


basher_reinstall()
{
  test $# -eq 1 || return 99
  basher uninstall "$1" || return
  basher install "$1" || return
}

u_s_add_repo()
{
  test $# -eq 2 -a -n "$1" -a -n "$2" || return 99
  git remote add "$@" || return
  git_update_from_repo "$1" || return
}

u_s_reinstall() # Repo
{
  test $# -le 1 || return 99
  test $# -gt 0 || set -- ${U_S_REPO}
  trueish "$offline" && return 1
  BASHER_FULL_CLONE=true basher_reinstall "$@"
  cd "$U_S"
  test "${U_S_REPO_ID}" = "origin" || {
    u_s_add_repo "$U_S_REPO_ID" "$U_S_REPO_URL"
  }
  git_reset_hard "" "${U_S_REPO_ID}"
}
