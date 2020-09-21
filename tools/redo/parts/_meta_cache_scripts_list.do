#!/usr/bin/env bash

## Build interpreted-scripts list

# List all plain-text files with initial shebang specifying some interpreter

# TODO: annotate data onto sh-files

lib_require statusdir-uc src match package build-htd std sys-htd vc-htd ctx-index

build_sd_cache "$(basename $1)" "$hostname-$APP_ID_BREV" "$(basename "$3")"
test ! -e "$1" -o -s "$1" || rm "$1"
true "${index_action:="$( test -e "$1" && echo update-index || echo init )"}"
generator=list_scripts \
    index_update files-index $index_action "$1" -- "" 4 "4d" "$1" "$3"

echo "Listed $(wc -l "$3"|awk '{print $1}') scripts"  >&2
build_sd_commit "$(basename $3)" "$hostname-$APP_ID_BREV" "$(basename "$1")"
build-stamp <$3
#
