#!/usr/bin/env bash

# Docker: manage user-scripts inside container


# Load lib: set vars to default values
dckr_lib_load()
{
  : "${docker_name:="u-s-dckr"}"
  : "${docker_image:="bvberkum/treebox:dev"}"

  : "${U_S_PATH:="/home/treebox/.basher/cellar/packages/bvberkum/user-scripts"}"
}

# Load and init libraries and log
dckr_load()
{
  test -n "$LOG" -a -x "$LOG" && dckr_log=$LOG || dckr_log=print_err

  dckr_lib_load && # NOTE: Because this is not loaded as a real lib. +U_s
  lib_load docker-sh docker-sh-htd &&
  lib_init docker-sh docker-sh-htd &&
  lib_assert docker-sh docker-sh-htd
}

# List running container names
dckr_list() #
{
  test $# -eq 0 || return
  dckr_load && docker_sh_names
}

# Initialize local treebox container instance
dckr_init() #
{
  test $# -eq 0 || return
  docker_sh_c_init()
  {
    ${dckr_pref}docker exec -u root "$1" \
      sh -c 'echo treebox:treebox | chpasswd' || return

    ${dckr_pref}docker exec -w /src/github.com/bvberkum/oil "$1" \
      sh -c 'git checkout 2a94f6ff && git clean -dfx && make configure && build/dev.sh minimal' || return

    # Accept Oil-shell install error
    local e=
    ${dckr_pref}docker exec -ti -u root -w /src/github.com/apenwarr/redo "$1" \
      sh -c 'git clean -dfx && ./redo install' || e=$?
    test "$e" = "126" || return
  }
  dckr_load && docker_sh_c require
}

# Remove U_s container instance
dckr_reset() #
{
  test $# -eq 0 || return
  dckr_load &&
    docker_sh_c delete "$docker_name" &&
  test -n "$dckr_log" || return 103
  $dckr_log note u-s:dckr "Removed container"
}

dckr_req() #
{
  test $# -eq 0 || return
  dckr_load && {
    # Return if container is running, else initialize one
    docker inspect --format '{{ .Id }}' "$docker_name" >/dev/null || return
  } || dckr_init
}

# Interactive execute in U-s container instance on PWD U_S_PATH
dckr_exec() # [Cmd...]
{
  dckr_load || return
  ${dckr_pref}docker exec -ti -w "$U_S_PATH" "$docker_name" "$@"
}

# Interactive login shell executed in U-s container (see dckr-exec)
dckr_shell()
{
  dckr_load || return
  test -n "$dckr_log" || return 103
  $dckr_log "note" "" "Executing '$*'" "$docker_shell"

  dckr_exec $docker_shell -li "$@"
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

  local repo_rev= repo_url= repo_id=
  u_s_devline_args "$2" "$3" "$1" || return

  dckr_load || return
  docker_sh_c_is_running || return

  dckr_cmd 'echo "Container U-s version and branch where at: $(git describe --always | tr "\\n" " " && git rev-parse --abbrev-ref HEAD )" >&2'

  dckr_exec git config --get remote.$repo_id.url >/dev/null || {

    dckr_exec git remote add "$repo_id" "$repo_url" || return
    $LOG "info" "$repo_id:$repo_rev" "$docker_name remote GIT added" "$repo_url"
  }
  $LOG "debug" "$repo_id:$repo_rev" "$docker_name fetching GIT..." "$repo_url"
  dckr_exec git fetch "$repo_id" || return
  dckr_exec git fetch --tags "$repo_id" || return
  $LOG "note" "$repo_id:$repo_rev" "$docker_name resetting GIT..." "$repo_url"
  dckr_exec git reset --hard $repo_id/$repo_rev || return
  $LOG "info" "$repo_id:$repo_rev" "$docker_name reset to defaults" "$repo_url"

  dckr_cmd 'echo "Container U-s version and branch now at: $(git describe --always | tr "\\n" " " && git rev-parse --abbrev-ref HEAD )" >&2'
}

#
