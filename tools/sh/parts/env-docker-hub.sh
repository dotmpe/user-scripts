#!/usr/bin/env bash

$LOG crit "" Starting...

ctx_if @Docker@Build || return 0
# log_name env-docker-hub

test ! -e ~/.local/etc/tokens.d/docker-hub-$DOCKER_NS.sh || {

  . ~/.local/etc/tokens.d/docker-hub-$DOCKER_NS.sh || return
}

: "${DOCKER_USERNAME:="$DOCKER_NS"}"
: "${INIT_LOG:="$PWD/tools/sh/log.sh"}"

test -n "${DOCKER_PASSWORD:-}" || {
  $INIT_LOG "error" "" "Docker Hub password required" "" 1
}


# Id: U-S:
