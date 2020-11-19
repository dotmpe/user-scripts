#!/usr/bin/env bash

ctx_if @Docker@Build || return 0

test ! -e ~/.local/etc/tokens.d/docker-hub-$DOCKER_NS.sh || {

  . ~/.local/etc/tokens.d/docker-hub-$DOCKER_NS.sh || return
}

: "${DOCKER_USERNAME:="$DOCKER_NS"}"
: "${INIT_LOG:="$PWD/tools/sh/log.sh"}"

test -n "${DOCKER_PASSWORD:-}" || {
  $INIT_LOG "error" "" "Docker Hub password required" "" 1
}


# Id: U-S:
