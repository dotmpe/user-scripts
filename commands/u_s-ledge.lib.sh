#!/usr/bin/env bash

## Ledge: keep sd_logdir inside image

# See Script.mpe:build#logging docs

u_s_ledge__man_1='
  lastbuild - see `lastbuilds 1`
  lastbuilds [NUM] - see `ledge-lastbuilds`

  listtags - list tags (project+branch-name) for all ledges
  pullall [TAGS...] - fetch every or given ledge from docker hub
  listfiles [TAGS...] - call `ledge_listsd` with all tags
  listlogs [TAGS...] - call `ledge_listlogs` with all tags

  ledge-pull - merge local logs for current project/branch from ledge
  ledge-exists - test by pulling ledge for project/branch
  ledge-tovolume - Create named volume from ledge data
  ledge-localclean - Remove u-s container and ledge volume
  ledge-showbuilds - List all builds for current project+branch
  ledge-listlogs
  ledge-listsd
  ledge-sumlogs
  ledge-fetchlogs
  ledge-refreshlogs
  ledge-pushlogs - Build new image from ~/.local/statusdir and publish
  ledge-lastbuilds

  ledge-* - See Script.mpe:build#logging docs
'

u_s_ledge_lib__load()
{
  true "${sd_logdir:="${STATUSDIR_ROOT:-$HOME/.local/statusdir/}log"}"
  sh_include env-docker-cache || return
}

ledge_tovolume()
{
  lib_require docker-sh || return
  docker_setup_volume_from_imagepath ledge \
    ledge-statusdir:/statusdir dotmpe/ledge:${1:-"$ledge_tag"}
}

# Remove container and volume created by ledge-tovolume
ledge_localclean()
{
  ${dckr_pref-}docker rm -f ledge >/dev/null
  ${dckr_pref-}docker volume rm ledge-statusdir >/dev/null
}

# Pull ledge-image and list entire log for current project
ledge_showbuilds()
{
  $LOG "note" "ledge:showbuilds" "Using ledge" "$ledge_tag"
  dckr_refresh_images dotmpe/ledge:$ledge_tag busybox || return
  ledge_do=builds ledge_foreach "$@"
}

# Pull ledge-image, or return non-zero if none exists at hub
ledge_exists()
{
  ${dckr_pref-}docker pull dotmpe/ledge:$ledge_tag >/dev/null
}

# Merge builds and results log (if exists) on local host with ledge-image
ledge_pull()
{
  $LOG "note" "ledge:pull" "Using ledge" "$ledge_tag"

  ledge_tovolume || return


  test ! -e /tmp/builds.log || rm /tmp/builds.log
  test ! -e "$builds_log" || {
    # XXX: file_backup $builds_log .list
    cp $builds_log /tmp/builds.log
  }

  # Merge local and ledge announce logs into one
  ${dckr_pref-}docker run -t --rm \
    --volumes-from ledge \
    busybox test -e /statusdir/log/travis-$PROJ_LBL.list && {

    {
      test ! -e /tmp/builds.log || cat /tmp/builds.log

      ${dckr_pref-}docker run -t --rm \
        --volumes-from ledge \
        busybox \
        cat /statusdir/log/travis-$PROJ_LBL.list

    } | tr -s '\r\n' '\n' | remove_dupes >$builds_log
  }
  test -s "$builds_log" -o ! -e "$builds_log" || rm "$builds_log"
  test ! -e "$builds_log" || wc -l $builds_log


  test ! -e /tmp/results.log || rm /tmp/results.log
  test ! -e "$results_log" || {
    # XXX: file_backup $results_log .list
    cp $results_log /tmp/results.log
  }

  # Merge local and ledge results logs into one
  ${dckr_pref-}docker run -t --rm \
    --volumes-from ledge \
    busybox test -e /statusdir/log/builds-$PROJ_LBL.list && {

    {
      test ! -e /tmp/results.log || cat /tmp/results.log

      ${dckr_pref-}docker run -t --rm \
        --volumes-from ledge \
        busybox \
        cat /statusdir/log/builds-$PROJ_LBL.list

    } | tr -s '\r\n' '\n' | remove_dupes >$results_log
  }
  test -s "$results_log" -o ! -e "$results_log" || rm "$results_log"
  test ! -e "$results_log" || wc -l $results_log

  ledge_localclean
}

ledge_foreach()
{
  ${dckr_pref-}docker pull busybox >/dev/null
  test $# -gt 0 || set -- "$ledge_tag"
  local tag; for tag in $@
  do
    {
      test "${tag:0:${#PROJ_LBL}}" = "$PROJ_LBL" -o \
        ${foreach_allprojects:-0} -eq 1
    } || {
      $LOG "warn" ":ledge-foreach" \
        "Ignoring other project or non-project tag" "$tag"
      continue # ignore other projects
    }
    ledge_tovolume $tag || return
    ${ledge_foreach:-"ledge_do"}
    ledge_localclean
  done
}

# List all log files from (current) ledge-image
ledge_listlogs()
{
  ${dckr_pref-}docker pull busybox >/dev/null
  ledge_do=logs ledge_foreach "$@"
}

ledge_listsd()
{
  ${dckr_pref-}docker pull busybox >/dev/null
  ledge_do=files ledge_foreach "$@"
}

# Count builds and results log lines from ledge-image
ledge_sumlogs()
{
  ${dckr_pref-}docker pull busybox >/dev/null
  ledge_do=sumlogs ledge_foreach "$@"
}

ledge_do()
{
  case "${ledge_do:-"sumlogs"}" in

    sumlogs )
        ${dckr_pref-}docker run -t --rm \
          --volumes-from ledge \
          busybox wc -l /statusdir/log/travis-$PROJ_LBL.list \
            /statusdir/log/builds-$PROJ_LBL.list || true
      ;;

    logs )
        $LOG notice ":ledge-do:logs" \
          "Logs on ledge for ${tag:$(( 1 + ${#PROJ_LBL} ))}" "$PROJ_LBL"
        ${dckr_pref-}docker run -t --rm \
          --volumes-from ledge \
          busybox find /statusdir/log -iname '*.list' -type f |
          tr -s '\r\n' '\n'
      ;;

    files )
      #${foreach_allprojects:-0} -eq 1
      #$LOG notices ":ledge-do:files" "Files on ledge for ${tag:$(( 1 + ${#PROJ_LBL} ))}" "$PROJ_LBL"

      for file in $( ${dckr_pref-}docker run -t --rm \
          --volumes-from ledge busybox \
          find /statusdir -type f | tr -s '\r\n' '\n' )
      do
        echo "$tag $file"
        #echo "file:'$file' ./ledge/$tag-$(basename "$file")"
        #${dckr_pref-}docker run -t --rm \
        #  --volumes-from ledge busybox \
        #  sed 's/[\n\r]//g' $file > "./ledge/$tag:$(basename "$file")"
      done
      ;;

    builds )
        ${dckr_pref-}docker run -t --rm \
          --volumes-from ledge \
          busybox \
          sed 's/[\n\r]//g' /statusdir/log/travis-$PROJ_LBL.list
      ;;

    * ) print_red "ledge-do:$ledge_do?"; return 1
      ;;
  esac
}

# Fetch files in logs-dir from all ledge-images (no merge or overwrite)
ledge_fetchlogs()
{
  test $# -eq 0 || return ${_E_GAE:-193}
  local ledge_tag ledge_log log_bn

  set -- web docker-hub
  lib_load "$@" && lib_init "$@"

  for ledge_tag in $( docker_hub_tags dotmpe/ledge )
  do
    $LOG "note" "ledge:fetchlog" "Pulling ledge-image" "$ledge_tag"
    ${dckr_pref-}docker pull dotmpe/ledge:$ledge_tag >/dev/null

    $LOG "note" "ledge:fetchlog" "Starting ledge" "$ledge_tag"
    ${dckr_pref-}docker create --name ledge \
      -v ledge-statusdir:/statusdir \
      dotmpe/ledge:$ledge_tag >/dev/null

    for ledge_log in $(${dckr_pref-}docker run -t --rm --volumes-from ledge \
        busybox find /statusdir -iname '*.list' -type f | tr -s '\r\n' '\n')
    do
      echo "Tag:'$ledge_tag' Log:'$ledge_log'" >&2
      ${dckr_pref-}docker run -t --rm --volumes-from ledge \
        busybox wc -l $ledge_log
      continue
      log_bn="$(basename "$ledge_log" .log)"
      log="$sd_logdir/$log_bn-$ledge_tag.list"

      ${dckr_pref-}docker run -t --rm --volumes-from ledge \
        busybox sed 's/[\n\r]//g' $ledge_log >"$log"

      print_green "" "Retrieved data for $ledge_tag' at <$log>"
    done

    ${dckr_pref-}docker rm -f ledge >/dev/null
  done
}

# Refresh ledge-image from remote, and (re)write local logs
ledge_refreshlogs()
{
  ${dckr_pref-}docker rmi -f dotmpe/ledge:$ledge_tag >/dev/null
  ledge_exists || return
  ledge_pull
}

# Push logs onto ledge
ledge_pushlogs()
{
  # Rebuild ledge (for this repo/branch)
  ${dckr_pref-}docker rmi -f dotmpe/ledge:$ledge_tag >/dev/null

  cp tools/docker/ledge/Dockerfile ${STATUSDIR_ROOT:?} || return

  ${dckr_pref-}docker build -qt dotmpe/ledge:$ledge_tag ${STATUSDIR_ROOT:?} && {
    print_yellow "" "Pushing new image... <$ledge_tag>"

    # Push new image
    ${dckr_pref-}docker push dotmpe/ledge:$ledge_tag >/dev/null &&
      print_green "" "Pushed announce/results logs onto ledge <$ledge_tag>" ||
      print_red "" "Failed pushing logs <$ledge_tag>"
  }
  rm ${STATUSDIR_ROOT:?}Dockerfile
}

ledge_buildlog_echo()
{
  echo "# Job-Nr Starttime Branch Commit-Range"
  while read -r start_time job_id job_nr branch commit_range build_id
  do
    echo $job_nr $(date --iso=min -d @${start_time:0:10}) $branch $commit_range
    test "${job_nr:-${build_id:--}}" != "-" || {
        $LOG warn "" "No Job-Nr/Build-Id job:$job_id branch:$branch"
        continue
    }

    grep -m1 '^#' ${STATUSDIR_ROOT:?}log/builds-$PROJ_LBL.list
    grep "${job_nr:-$build_id}" ${STATUSDIR_ROOT:?}log/builds-$PROJ_LBL.list || continue
  done
}

ledge_lastbuilds () # [PROJ_LBL] ~ [NUM=3]
{
  local n=${1:-3}
  read_nix_style_file ${STATUSDIR_ROOT:?}log/travis-$PROJ_LBL.list |
    tail -n$n |
    ledge_buildlog_echo
}

#
