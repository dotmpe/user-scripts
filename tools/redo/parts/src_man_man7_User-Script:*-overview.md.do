#!/usr/bin/env bash
## Build shell lib overview in Pandoc Markdown man format
# Created: 2020-08-31
set -euo pipefail

local topic=$(basename "${1:11}" -overview.md) \
    lib_id=$(basename "${1:23}" -overview.md)
{
  grep "^$lib_id\>"$'\t' .cllct/src/sh-libs.list ||
    $LOG error "" "Cannot build lib docs" "$lib_id" $?
} |
while read lib_id src
do
  # Get source description label
  sd="$(grep -m1 "^## .*" $src | sed 's/^## //')" || true
  true "${sd:="$lib_id library overview"}"
  echo "% ${topic^^}(7) User-Script: $sd | $version"

  pragma="$(grep -m1 "^#pragma .*" $src | sed 's/^#pragma //')" || true
  true "${pragma:=""}"

  # TODO: add initial comment to docs
  #while read line
  #do case "$line" in
  #  "# "* ) echo "${line:2}" ;;
  #  *"() # "* ) echo "$line";echo ;;
  #  * ) continue ;;
  #esac; done <"$src"

  printf "\nFunctions:\n:"
  for f in $(sort -u .cllct/src/functions/$lib_id-lib.func-list)
  do echo "  - $f"
  done

  echo ""
  echo "Depends on:"
  deps=($(shopt -s nullglob && sort -u .cllct/src/functions/$lib_id-lib/*.func-deps))
  bins=()
  funcs=()
  for d in ${deps[@]}
  do
    test -x "$(which $d)" && { bins+=($d) ; continue; }
    funcs+=($d)
  done
  echo ": - Functions (${#funcs[@]}): ${funcs[*]}"
  echo "  - Commands (${#bins[@]}): ${bins[*]}"
done
