#!/usr/bin/env bash

# Ledge: keep sd_logsdir inside image

u_s_ledge_lib_load()
{
  true "${sd_logsdir:="$HOME/.statusdir/logs"}"
}

# Pull ledge-image and list entire log for current project
ledge_showbuilds()
{
  sh_include env-docker-cache || return

  $LOG "note" "ledge:showbuilds" "Using ledge" "$ledge_tag"
  ${dckr_pref}docker pull dotmpe/ledge:$ledge_tag >/dev/null || return

  ${dckr_pref}docker pull busybox >/dev/null
  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    dotmpe/ledge:$ledge_tag >/dev/null

  ${dckr_pref}docker run -t --rm \
      --volumes-from ledge \
      busybox \
      sed 's/[\n\r]//g' /statusdir/logs/travis-$PROJ_LBL.list

  ${dckr_pref}docker rm -f ledge >/dev/null
  ${dckr_pref}docker volume rm ledge-statusdir >/dev/null
}

# Pull ledge-image, or return non-zero if none exists at hub
ledge_exists()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker pull dotmpe/ledge:$ledge_tag >/dev/null
}

# Merge local builds and results log (if exists) with ledge-image
ledge_pull()
{
  ${dckr_pref}docker pull busybox >/dev/null
  $LOG "note" "ledge:pull" "Using ledge" "$ledge_tag"

  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    dotmpe/ledge:$ledge_tag >/dev/null

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

# List all log files from (current) ledge-image
ledge_listlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker pull busybox >/dev/null

  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    dotmpe/ledge:$ledge_tag >/dev/null

  ${dckr_pref}docker run -t --rm \
    --volumes-from ledge \
    busybox find /statusdir/logs/ -type f || true

  ${dckr_pref}docker rm -f ledge >/dev/null
  ${dckr_pref}docker volume rm ledge-statusdir >/dev/null
}

# Count builds and results log lines from ledge-image
ledge_sumlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker pull busybox >/dev/null

  ${dckr_pref}docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    dotmpe/ledge:$ledge_tag >/dev/null

  ${dckr_pref}docker run -t --rm \
    --volumes-from ledge \
    busybox wc -l /statusdir/logs/travis-$PROJ_LBL.list \
      /statusdir/logs/builds-$PROJ_LBL.list || true

  ${dckr_pref}docker rm -f ledge >/dev/null
  ${dckr_pref}docker volume rm ledge-statusdir >/dev/null
}

# Fetch files in logs-dir from all ledge-images (no merge or overwrite)
ledge_fetchlogs()
{
  local log_bn
  # requires docker-hub.lib
  lib_load docker-hub
  lib_init docker-hub
  docker_hub_tags dotmpe/ledge | while read ledge_tag
  do
    $LOG "note" "ledge:fetchlog" "Pulling ledge-image" "$ledge_tag"
    ${dckr_pref}docker pull dotmpe/ledge:$ledge_tag >/dev/null

    $LOG "note" "ledge:fetchlog" "Starting ledge" "$ledge_tag"
    ${dckr_pref}docker create --name ledge \
      -v ledge-statusdir:/statusdir \
      dotmpe/ledge:$ledge_tag >/dev/null

    ${dckr_pref}docker run -t --rm \
      --volumes-from ledge \
      busybox ls /statusdir/logs/*.list | while read ledge_log
      do
        log_bn="$(basename "$ledge_log")"
        test ! -e "$sd_logsdir/$log_bn" || {
          $LOG "warn" "" "Skipped existing" "$log_bn"
        }

        echo ledge_log=$ledge_log
        #${dckr_pref}docker run -t --rm \
        #  --volumes-from ledge \
        #  busybox cat /statusdir/logs/*.list | while read ledge_log
      done
  done
}

# Refresh ledge-image from remote, and (re)write local logs
ledge_refreshlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  ${dckr_pref}docker rmi -f dotmpe/ledge:$ledge_tag >/dev/null

  ledge_exists || return
  ledge_pull
}

# Push logs onto ledge
ledge_pushlogs()
{
  test -n "${ledge_tag:-}" || sh_include env-docker-cache

  # Rebuild ledge (for this repo/branch)
  ${dckr_pref}docker rmi -f dotmpe/ledge:$ledge_tag >/dev/null

  cp test/docker/ledge/Dockerfile ~/.statusdir
  ${dckr_pref}docker build -qt dotmpe/ledge:$ledge_tag ~/.statusdir && {
    print_yellow "" "Pushing new image... <$ledge_tag>"

    # Push new image
    ${dckr_pref}docker push dotmpe/ledge:$ledge_tag >/dev/null &&
      print_green "" "Pushed build announce log line onto ledge" ||
      print_red "" "Failed pushing build announce log line"
  }
}

#
