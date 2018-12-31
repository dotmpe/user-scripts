#!/bin/ash

announce 'Initializing for build-cache'

echo "$DOCKER_HUB_PASSWD" | docker login --username bvberkum --password-stdin


mkdir -p ~/.statusdir/{logs,tree,index}

builds_log="$HOME/.statusdir/logs/travis-user-scripts.list"

echo '------------ Last log'
wc -l "$builds_log" || true
tail -n 1 "$builds_log" || true
echo $TRAVIS_TIMER_START_TIME \
	$TRAVIS_JOB_ID \
	$TRAVIS_JOB_NUMBER \
	$TRAVIS_BRANCH \
	$TRAVIS_COMMIT_RANGE >>"$builds_log"
echo '------------ New log'
tail -n 1 "$builds_log"
echo '------------'


#docker pull bvberkum/ledge:latest && {
#
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
docker build -t bvberkum/ledge:$TRAVIS_BRANCH ~/.statusdir/
docker push bvberkum/ledge:$TRAVIS_BRANCH


#docker run \
#  --volume ledge:/statusdir \
#  --volume $HOME/.statusdir:$HOME/.statusdir \
#  -ti --rm instrumentisto/rsync-ssh rsync -avzui "$HOME/.statusdir/" "/statusdir"

#docker run \
#  --volume ledge:/statusdir \
#  --volume $HOME/.statusdir:$HOME/.statusdir \
#  -ti --rm instrumentisto/rsync-ssh ls -la "$HOME/.statusdir/" "/statusdir"
