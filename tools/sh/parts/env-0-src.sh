#!/usr/bin/env bash

: "${SRC_PREFIX:="/src"}"
: "${VND_GH_SRC:="$SRC_PREFIX/github.com"}"
: "${VND_SRC_PREFIX:="$VND_GH_SRC"}"

# XXX: export VND_SRC_PREFIX=$HOME/build
#test -d "$VND_SRC_PREFIX" || mkdir -vp $VND_SRC_PREFIX

export SRC_PREFIX VND_SRC_PREFIX VND_GH_SRC
