#!/usr/bin/env bash
set -euo pipefail
IFS=$' \t\n'
PATH+=:$U_S/tool/bash/part
. user-script.build.xredo.bash
cache=${C:?}/${XREDO_TARGET//[^A-Za-z0-9_]/-}
slist=$cache.sources.list
export EWD
us-pp --sources=$slist --output=$3 $1.build
redo-stamp < "$3"
mapfile -t srcs < "$slist"
redo-ifchange "$1.build" "${srcs[@]}"
