#!/usr/bin/env bash


# XXX: Get checkouts, tool installs and rebuild env (PATH etc.)
VND_SRC_PREFIX=$HOME/build
. ./tool/sh/parts/env-0-src.sh
set -eo pipefail
. $U_S/tool/sh/parts/init.sh
$INIT_LOG "note" "" "Installing prerequisite repos" "$VND_SRC_PREFIX"
init-deps dependencies.txt
set -euo pipefail
