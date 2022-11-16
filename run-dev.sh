#!/usr/bin/env bash
set -eu

docker rm -f user-conf-dev || true

image=dotmpe/treebox:edge

PPWD=$(pwd -P)
gh_keyfile=~/.ssh/id_rsa
kbn=id_rsa
set -x
docker run \
  -ti \
  --rm \
  --name user-script-dev \
  --volume /dev/log:/dev/log \
  --volume "$(realpath /etc/localtime)":/etc/localtime:ro \
  --volume "$(realpath $gh_keyfile):/home/treebox/.ssh/$kbn" \
  --volume "$(realpath ~/.ssh/known_hosts)":/home/treebox/.ssh/known_hosts \
  --volume /srv/project-local/user-conf-dev:/srv/project-local/user-conf-dev \
  --volume "$PPWD":/srv/project-local/user-scripts \
  --volume "$PPWD:$PPWD" \
  -u treebox \
  -e UC_LOG_LEVEL=7 \
  -e USER=treebox \
  -e TERM=xterm-256color \
  -e LOG="$PWD"/tools/sh/log.sh \
  -w "$PPWD" \
  "$image" "$@" </dev/tty

#
