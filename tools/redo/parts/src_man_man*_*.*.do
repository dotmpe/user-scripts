#!/usr/bin/env bash
# Created: 2020-08-31
set -euo pipefail

build-ifchange $U_S/commands/u_s-man.lib.sh $U_S_MAN $_ENV || return
lib_require u_s-man || return
local b=$( echo $1 | cut -d/ -f1,2,3 )
mkdir -p $b
local p=$(( ${#b} + 1 ))
local topic=$(echo "${1:$p}" | cut -d. -f1) \
    section=$(basename "$1" | cut -d. -f2)
{ build_manual_src_parts $section $topic >"$3"
} || {
  $LOG error "" "Building man page parts" "$topic($section)" $?
}
build-stamp <"$3"
