#!/usr/bin/env bash

$INIT_LOG "note" "" "Adding SCRIPTPATH" "$(dirname "${BASH_SOURCE[0]}")"
SCRIPTPATH="$SCRIPTPATH:$(dirname "${BASH_SOURCE[0]}")/src/sh/lib"
test -z "${BASH:-}" || {
  SCRIPTPATH="$SCRIPTPATH:$(dirname "${BASH_SOURCE[0]}")/src/bash/lib"
}
SCRIPTPATH="$SCRIPTPATH:$(dirname "${BASH_SOURCE[0]}")/commands"

test -n "${U_S:-}" || U_S="$(dirname "${BASH_SOURCE[0]}")"
