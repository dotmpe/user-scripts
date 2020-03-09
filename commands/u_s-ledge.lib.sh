#!/usr/bin/env bash

# Ledge: keep sd_logsdir inside image


# Pull ledge-image and list entire log for current project
ledge_showbuilds()
{
  sh_include env-docker-cache

  $LOG "note" "" "Using ledge" "$ledge_tag"
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

# Write local builds and results log from ledge-image
ledge_pull()
{
  ${dckr_pref}docker pull busybox >/dev/null

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
