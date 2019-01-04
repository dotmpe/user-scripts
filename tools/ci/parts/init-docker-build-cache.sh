#!/usr/bin/env bash

ci_announce 'Initializing for build-cache'


test -n "${DOCKER_HUB_PASSWD:-}" || {
  $LOG "error" "" "Docker Hub password required"
  return
}

ci_announce "Logging into docker hub"
echo "$DOCKER_HUB_PASSWD" | \
  ${dckr_pref} docker login --username $DOCKER_USERNAME --password-stdin

mkdir -p ~/.statusdir/{logs,tree,index}

PROJ_LBL=$(basename "$TRAVIS_REPO_SLUG")
builds_log="$HOME/.statusdir/logs/travis-$PROJ_LBL.list"
ledge_tag="$(printf %s "$PROJ_LBL-$TRAVIS_BRANCH" | tr -c 'A-Za-z0-9_-' '-')"

${dckr_pref} docker pull bvberkum/ledge:$ledge_tag && {

  ${dckr_pref} docker create --name ledge \
    -v ledge-statusdir:/statusdir \
    bvberkum/ledge:$ledge_tag

  ${dckr_pref} docker volume ls

  ${dckr_pref} docker run --rm \
    --volumes-from ledge \
    -v ledge-statusdir:/statusdir \
    busybox find /statusdir/ || true

  ${dckr_pref} docker run --rm -v ledge-statusdir busybox find /statusdir/ || true

  {
    test ! -e "$builds_log" || {
      cp $builds_log /tmp/builds.log
      cat /tmp/builds.log
    }

    ${dckr_pref} docker run --rm \
      -v ledge-statusdir:/statusdir \
      busybox \
      cat /statusdir/logs/travis-$PROJ_LBL.list
  } | sort -u >$builds_log

  ${dckr_pref} docker delete ledge

} || true

ci_announce 'Last log'
wc -l "$builds_log" || true
tail -n 1 "$builds_log" || true
echo $TRAVIS_TIMER_START_TIME \
	$TRAVIS_JOB_ID \
	$TRAVIS_JOB_NUMBER \
	$TRAVIS_BRANCH \
	$TRAVIS_COMMIT_RANGE >>"$builds_log"
ci_announce 'New log'
tail -n 1 "$builds_log"

##  docker run -it --rm \
##	-v some_volume:/volume -v /tmp:/backup alpine \
##    tar -cjf /backup/some_archive.tar.bz2 -C /volume ./
#
##  docker create --name ledge bvberkum/ledge
#
##  docker run \
##  --volume ledge:/statusdir \
##  --volume $HOME/.statusdir:$HOME/.statusdir \
##  -ti --rm instrumentisto/rsync-ssh rsync -avzui "/statusdir/" "$HOME/statusdir"
#
#  true
#
#} || {
#
#  #docker create --name ledge bvberkum/ledge:build
#}


cp test/docker/ledge/Dockerfile ~/.statusdir
${dckr_pref} docker build -qt bvberkum/ledge:$ledge_tag ~/.statusdir
${dckr_pref} docker push bvberkum/ledge:$ledge_tag


#docker run \
#  --volume ledge:/statusdir \
#  --volume $HOME/.statusdir:$HOME/.statusdir \
#  -ti --rm instrumentisto/rsync-ssh rsync -avzui "$HOME/.statusdir/" "/statusdir"

#docker run \
#  --volume ledge:/statusdir \
#  --volume $HOME/.statusdir:$HOME/.statusdir \
#  -ti --rm instrumentisto/rsync-ssh ls -la "$HOME/.statusdir/" "/statusdir"
