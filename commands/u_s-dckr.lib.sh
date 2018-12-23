#!/bin/ssh

dckr_lib_load()
{
  : "${docker_name:="u-s-dckr"}"
  : "${docker_image:="bvberkum/treebox:dev"}"

  : "${U_S_PATH:="/home/treebox/.basher/cellar/packages/bvberkum/user-scripts"}"
}

dckr_load()
{
  test -n "$LOG" -a -x "$LOG" && dckr_log=$LOG || dckr_log=print_err

  dckr_lib_load && # Because this is not loaded as a real lib.
  lib_load docker-sh docker-sh-htd &&
  lib_init docker-sh docker-sh-htd &&
  lib_assert docker-sh docker-sh-htd
}

dckr_list() #
{
  test $# -eq 0 || return
  dckr_load && docker_sh_names
}

# Initialize local treebox container
dckr_init() #
{
  test $# -eq 0 || return
  docker_sh_c_init()
  {
    ${dckr_pref}docker exec -u root "$1" \
      sh -c 'echo treebox:treebox | chpasswd'
    ${dckr_pref}docker exec -w /src/github.com/bvberkum/oil "$1" \
      sh -c 'git checkout 2a94f6ff && git clean -dfx && make configure && build/dev.sh minimal' &&
    ${dckr_pref}docker exec -ti -u root -w /src/github.com/apenwarr/redo "$1" \
      sh -c 'git clean -dfx && ./redo install'
  }
  dckr_load && docker_sh_c require
}

dckr_reset() #
{
  test $# -eq 0 || return
  dckr_load &&
    docker_sh_c delete "$docker_name" &&
  $dckr_log note u-s:dckr "Removed container"
}

dckr_req() #
{
  test $# -eq 0 || return
  dckr_load && {
    docker inspect --format '{{ .Id }}' "$docker_name" >/dev/null || return
  } || dckr_init
}

dckr_exec()
{
  dckr_load &&
    ${dckr_pref}docker exec -ti -w "$U_S_PATH" "$docker_name" "$@"
}

dckr_shell()
{
  $dckr_log "note" "" "Executing '$*'" "$docker_shell"

  dckr_load &&
    dckr_exec $docker_shell -li "$@"
}

dckr_cmd()
{
  dckr_shell -c "$*"
}

dckr_update()
{
  test $# -eq 0 || return
  dckr update
}

dckr()
{
  test $# -gt 0 || set -- git-version
  dckr_req &&
    dckr_cmd ./bin/u-s "$@"
}

#
