#!/usr/bin/env bash

# Docker: manage user-scripts inside container


# Load lib: set vars to default values
dckr_lib_load()
{
  : "${docker_name:="u-s-dckr"}"
  : "${docker_image:="bvberkum/sandbox:dev"}"

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
      sh -c 'echo treebox:treeobx | chpasswd && \
          usermod -a -G docker treebox && \
          echo "treebox    ALL=NOPASSWD:$(which docker) *" >>/etc/sudoers.d/treebox' || return

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
  ${dckr_pref}docker exec -ti -u treebox -w "$U_S_PATH" "$docker_name" "$@"
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
  dckr_reset
  dckr_init
  dckr_test_suite
}

dckr_showlog()
{
  sh_include env-docker-cache

  ${dckr_pref}docker pull bvberkum/ledge:$ledge_tag >/dev/null || return

  ${dckr_pref}docker pull busybox >/dev/null
  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    bvberkum/ledge:$ledge_tag >/dev/null

  ${dckr_pref}docker run -t --rm \
      --volumes-from ledge \
      busybox \
      sed 's/[\n\r]//g' /statusdir/logs/travis-$PROJ_LBL.list

  ${dckr_pref}docker rm -f ledge >/dev/null
  ${dckr_pref}docker volume rm ledge-statusdir >/dev/null
}

dckr_ledge_exists()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker pull bvberkum/ledge:$ledge_tag >/dev/null
}

dckr_ledge_pull()
{
  ${dckr_pref}docker pull busybox >/dev/null

  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    bvberkum/ledge:$ledge_tag >/dev/null

  ${dckr_pref}docker run -t --rm \
    --volumes-from ledge \
    busybox test -e /statusdir/logs/travis-$PROJ_LBL.list && {

    test ! -e /tmp/builds.log || rm /tmp/builds.log
    test ! -e "$builds_log" || cp $builds_log /tmp/builds.log
    {
      test ! -e /tmp/builds.log || cat /tmp/builds.log

      ${dckr_pref}docker run -t --rm \
        --volumes-from ledge \
        busybox \
        sed 's/[\n\r]//g' /statusdir/logs/travis-$PROJ_LBL.list

    } | $gsed 's/[\n\r]//g' | sort -u >$builds_log
  }

  ${dckr_pref}docker run -t --rm \
    --volumes-from ledge \
    busybox test -e /statusdir/logs/builds-$PROJ_LBL.list && {

    test ! -e /tmp/results.log || rm /tmp/results.log
    test ! -e "$results_log" || cp $results_log /tmp/results.log
    {
      test ! -e /tmp/results.log || cat /tmp/results.log

      ${dckr_pref}docker run -t --rm \
        --volumes-from ledge \
        busybox \
        sed 's/[\n\r]//g' /statusdir/logs/builds-$PROJ_LBL.list

    } | $gsed 's/[\n\r]//g' | sort -u >$results_log
  }

  ${dckr_pref}docker rm -f ledge >/dev/null
  ${dckr_pref}docker volume rm ledge-statusdir >/dev/null
}

dckr_listlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker pull busybox >/dev/null

  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    bvberkum/ledge:$ledge_tag >/dev/null

  ${dckr_pref}docker run -t --rm \
    --volumes-from ledge \
    busybox wc -l /statusdir/logs/travis-$PROJ_LBL.list \
      /statusdir/logs/builds-$PROJ_LBL.list || true

  ${dckr_pref}docker rm -f ledge >/dev/null
  ${dckr_pref}docker volume rm ledge-statusdir >/dev/null
}

dckr_refreshlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker rmi -f bvberkum/ledge:$ledge_tag >/dev/null

  dckr_ledge_exists || return
  dckr_ledge_pull
}

# Push logs onto ledge
dckr_pushlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  # Rebuild ledge (for this repo/branch)
  ${dckr_pref}docker rmi -f bvberkum/ledge:$ledge_tag >/dev/null

  cp test/docker/ledge/Dockerfile ~/.statusdir
  ${dckr_pref}docker build -qt bvberkum/ledge:$ledge_tag ~/.statusdir && {
    print_yellow "" "Pushing new image... <$ledge_tag>"

    # Push new image
    ${dckr_pref}docker push bvberkum/ledge:$ledge_tag >/dev/null &&
      print_green "" "Pushed build announce log line onto ledge" ||
      print_red "" "Failued pushing build announce log line"
  }
}

#
