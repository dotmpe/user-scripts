#!/usr/bin/env bash

context_status_tab () # Context-List
{
  local t tags=

  local dtime mtime entry base year weeks days title
  while read dtime mtime entry base year weeks days title
  do
    t=
    test ${dtime:-'-'} = - && deleted=- ||
      deleted="$(date --iso=min -d $dtime | tr -d ':-' | tr 'T' '-')"
    echo "$deleted $modified $entry: $title doy:$days woy:$weeks $t"
  done<$1
}

# Id: U-S:tools/bash/build/context-status-tab.sh                   ex:ft=bash:
