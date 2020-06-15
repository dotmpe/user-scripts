#!/bin/sh

$INIT_LOG "note" "" "Adding SCRIPTPATH" "$(dirname "$SCRIPT_SOURCE")"
SCRIPTPATH="$SCRIPTPATH:$(dirname "$SCRIPT_SOURCE")/src/sh/lib"
SCRIPTPATH="$SCRIPTPATH:$(dirname "$SCRIPT_SOURCE")/commands"

test -n "${U_S-}" || U_S="$(dirname "$SCRIPT_SOURCE")"
