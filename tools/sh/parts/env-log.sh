#!/bin/sh

. "$sh_tools/parts/env-log-reinit.sh" ||
    $INIT_LOG "error" "" "Failed env-part" "$? log-reinit"

. "$sh_tools/parts/env-init-log.sh" ||
    $INIT_LOG "error" "" "Failed env-part" "$? init-log"
#
