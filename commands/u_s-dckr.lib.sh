#!/usr/bin/env bash

## Docker: manage user-scripts inside container

#shellcheck disable=2120 # XXX: check args


# Load lib: set vars to default values
dckr_lib_load()
{
  : "${docker_name:="u-s-dckr"}"
  : "${docker_image:="dotmpe/sandbox:dev"}"

  : "${U_S_PATH:="/home/treebox/.basher/cellar/packages/dotmpe/user-scripts"}"
}

# Load and init libraries and log
dckr_load()
{
  test -n "$LOG" -a -x "$LOG" && dckr_log=$LOG || dckr_log=print_err

  dckr_lib_load && # NOTE: Because this is not loaded as a real lib. +U_s
  lib_require docker-sh-htd && lib_init docker-sh-htd
}

# List running container names
dckr_list() #
{
  test $# -eq 0 || return
  dckr_load && docker_sh_names
}

# Initialize local treebox container instance
dckr_init () # ~
{
  test $# -eq 0 || return
  docker_sh_c_init() # sh:no-stat
  {
    #shellcheck disable=2086
    ${dckr_pref-}docker exec -u root "$1" sh -c '
      usermod -a -G docker treebox;
      apt-get update -q && apt-get install -qqy pass
    ' || return

    #shellcheck disable=2086
    ${dckr_pref-}docker exec -w /src/github.com/dotmpe "$1" \
      sh -c 'mkdir /src/github.com/ztombol &&
        cd /src/github.com/ztombol &&
        git clone https://github.com/ztombol/bats-support &&
        git clone https://github.com/ztombol/bats-assert &&
        git clone https://github.com/ztombol/bats-file
    ' || return

    #shellcheck disable=2086
    ${dckr_pref-}docker exec -w /src/github.com/dotmpe "$1" \
      sh -c 'git clone https://github.com/dotmpe/oil' || return

    #shellcheck disable=2086
    ${dckr_pref-}docker exec -w /src/github.com/dotmpe/oil "$1" \
      sh -c 'git checkout 2a94f6ff && git clean -dfx && make configure && build/dev.sh minimal' || return

    # Accept redo-shell install error
    local e=

    #shellcheck disable=2086
    ${dckr_pref-}docker exec "$1" \
      sh -c '
mkdir -p /src/github.com/apenwarr
cd /src/github.com/apenwarr

git clone https://github.com/apenwarr/redo

cd redo && git show-ref && git rev-parse && git rev-parse --abbrev-ref HEAD
git status
git checkout redo-0.42c
ls -la redo || true
git ls-files

      ' || return

    #${dckr_pref-}docker exec -u root "$1" \
    #  sh -c 'echo treebox:treeobx | chpasswd && \
    #      usermod -a -G docker treebox && \
    #      echo "treebox    ALL=NOPASSWD:$(which docker) *" >>/etc/sudoers.d/treebox' || return
  }

  #shellcheck disable=2086
  dckr_load && docker_sh_c require &&
  ${dckr_pref-}docker exec -ti -u root -w /src/github.com/apenwarr/redo \
    "$docker_name" \
      sh -c '

git clean -dfx
DESTDIR= PREFIX=/usr/local ./do -j10 install

  ' || return
}

# Remove U_s container instance
dckr_deinit ()
{
  test $# -eq 0 || return 98
  dckr_load && docker_sh_c delete "$docker_name" &&
  $dckr_log note u-s:dckr "Removed container"
}

dckr_reset () #
{
  test $# -eq 0 || return 98
  dckr_load &&
  docker_sh_c_exists $docker_name && {
    dckr_deinit || return
  }
  dckr_init
}

dckr_req () #
{
  test $# -eq 0 || return 98
  dckr_load && {
    # Return if container is running, else initialize one
    docker inspect --format '{{ .Id }}' "$docker_name" >/dev/null || return
  } || dckr_init
}

# Interactive execute in U-s container instance on PWD U_S_PATH
dckr_exec() # [Cmd...]
{
  dckr_load || return
  #shellcheck disable=2086
  ${dckr_pref-}docker exec -ti -u treebox -w "$U_S_PATH" "$docker_name" "$@"
}

# Interactive login shell executed in U-s container (see dckr-exec)
dckr_shell()
{
  dckr_load || return
  test -n "$dckr_log" || return 103
  #shellcheck disable=2154
  "$dckr_log" "note" "" "Executing '$*'" "$docker_shell"

  dckr_exec "$docker_shell" -li "$@"
}

# Run command in interactive container login shell (see dckr-shell)
dckr_cmd()
{
  dckr_shell -c "$*"
}

# Namespace/proxy to relay u-s sub-command to container instance's u-s script
dckr()
{
  test $# -gt 0 || set -- version
  dckr_req || return
  local scriptname=$scriptname:u-s:$docker_name
  dckr_cmd ./bin/u-s "$@"
}

# update u-s install inside container to release version
dckr_update()
{
  test $# -eq 0 || return
  dckr update
}

# Update U-s install to version (from repo) from outside container (when all
# else fails; see dckr-update).
dckr_update_ext() # [Repo-Revision] [Repo-Id [Repo-Url]]
{
  test $# -le 3 || return 99

  while test $# -le 3 ; do set -- "$@" "" ; done

  local repo_rev="" repo_url="" repo_id=""
  u_s_devline_args "$2" "$3" "$1" || return

  dckr_load || return
  docker_sh_c_is_running || return

  #shellcheck disable=2016
  dckr_cmd 'echo "Container U-s version and branch where at: $(git describe --always | tr "\\n" " " && git rev-parse --abbrev-ref HEAD )" >&2'

  dckr_exec git config --get remote."$repo_id".url >/dev/null || {

    dckr_exec git remote add "$repo_id" "$repo_url" || return
    $LOG "info" "$repo_id:$repo_rev" "$docker_name remote GIT added" "$repo_url"
  }
  $LOG "debug" "$repo_id:$repo_rev" "$docker_name fetching GIT..." "$repo_url"
  dckr_exec git fetch "$repo_id" || return
  dckr_exec git fetch --tags "$repo_id" || return
  $LOG "note" "$repo_id:$repo_rev" "$docker_name resetting GIT..." "$repo_url"
  dckr_exec git reset --hard "$repo_id/$repo_rev" || return
  $LOG "info" "$repo_id:$repo_rev" "$docker_name reset to defaults" "$repo_url"

  #shellcheck disable=2016
  dckr_cmd 'echo "Container U-s version and branch now at: $(git describe --always | tr "\\n" " " && git rev-parse --abbrev-ref HEAD )" >&2'
}

dckr_update_deps()
{
  dckr_exec ./tools/sh/parts/init.sh init-deps
}

dckr_test_suite()
{
  dckr_update_ext feature/docker-ci
  dckr_update_deps
  $INIT_LOG "note" "" "Starting test suite"
  dckr_shell ./sh-main run-baseline
  dckr_exec ./sh-main run-ci
  dckr_exec ./sh-main run-test
}

dckr_retest_suite()
{
  dckr_reset &&
  dckr_init &&
  dckr_test_suite
}

dckr_refresh_images() # Images
{
  #shellcheck disable=2086
  for img in "$@"
  do ${dckr_pref-}docker pull $img >/dev/null || return
  done
}

#
