#!/usr/bin/env bash

## Annotate shell libraries


set +C

# TODO:add dependency for each script file on this target,
# keep a simple list with lib src names and grep title label and head comment
# as rest-line for sh-files.

listsym="&source-list"
list=.meta/cache/source-sh.list

build-ifchange "$listsym" || return

build_env_declare us-libs || return

lib_require statusdir-uc src match package build-htd std sys-htd vc-htd ctx-index || return

#build_sd_cache "$(basename $1)" "$hostname-$APP_ID_BREV" "$(basename "$3")"
#test ! -e "$1.bup" || {
#  cat "$1.bup" >"$3"
#  exit
#}

true "${index_action:="$( test -e "$1" && echo update-index || echo init )"}"
generator=list_lib_sh_files \
    index_update files-index $index_action "$1" -- "" 4 "4d" "$1" "$3"

echo "Listed $(wc -l "$3"|awk '{print $1}') shell libraries"  >&2
#build_sd_commit "$(basename $3)" "$hostname-$APP_ID_BREV" "$(basename "$1")"
build-stamp <$3
test ! -e "$1" -o -s "$1" || rm "$1"
#
