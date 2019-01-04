#!/bin/sh

# TODO: Describe all repos on SCRIPTPATH...
# XXX: just take a SRC-PREFIX or other dir and take each dir as a GIT
# checkout,, or dir of checkouts.
user_repos() # [match-repo] [match-group-or-team] [github.com] [Vnd-Src-Prefix]
{
  test $# -gt 0 || set -- '*'
  test $# -gt 1 || set -- "$1" '*'
  test $# -gt 2 || set -- "$1" "$2" "$VND_SRC_PREFIX"
  test -n "$3"  || set -- "$1" "$2" 'github.com'
  test $# -gt 4 || set -- "$1" "$2" "$3" "$SRC_PREFIX"
  test -n "$4"  || set -- "$1" "$2" "$3" "/src/"

  print_err "info" "u-s:user-repos" "Listing user-checkouts" "$*"
  for user_repo in $4$3/$1/$2
  do
    test -d "$user_repo" || {
      print_err "warn" "" "Expected directory '$user_repo'"
      continue
    }
    test -e $user_repo/.git && {
      print_user_repo_description "$user_repo" ||
        print_err "error" "" "During stat" "$user_repo"
      continue

    } || {
      for y in $user_repo/*
      do
        test -d "$y" || continue
        test -e $y/.git && {
          print_user_repo_description "$y" ||
            print_err "error" "" "During stat" "$y"
        } ||
          print_err "error" "" "Unkown" "$y"
        done
    }
  done
}

#
print_user_repo_description()
{
  { # Try to validate the .git is OK to catch some kinds of repo failures, but
    # not all. GIT fsck has no --quick or --quiet
    cd "$1" && git status
  } >/dev/null || return

  local descr="$( cd "$1" >/dev/null && git describe --always)"
  test -n "$descr" || return
  echo "$1 at GIT $descr"
}
