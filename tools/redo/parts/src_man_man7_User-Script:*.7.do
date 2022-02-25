#!/usr/bin/env bash
# Created: 2020-08-31
set -euo pipefail

local topic=$(echo "${1:13}" | cut -d. -f1) section=7
build-ifchange $U_S_MAN src/md/man/$topic-overview.md || return

lib_require u_s-man || return
mkdir -p src/man/man7
{ build_manual_page src/md/man/$topic-overview.md >"$3"
} || {
  $LOG error "" "Building man page" "$topic($section)" $?
}
build-stamp <"$3"
