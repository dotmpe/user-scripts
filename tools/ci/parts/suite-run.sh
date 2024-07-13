#!/usr/bin/env bash

# Execute lines from table, source part if cmdline starts with undefined type
suite_run () # Execute table specs ~ Table Suite [Prefix]
{
  test $# -ge 2 -a -f "${1:-}" -a $# -le 3 || return 98

  local suitelines
  # Get command lines for suite
  suitelines="$( suite_from_table "$1" Parts "$2" "${3:-}" )" || return
  OLDIFS="$IFS"
  IFS=$'\n'; for suiteline in $suitelines;
  do
    suite_stage=$(str_id "$suiteline")
    export_stage "$suite_stage" && announce_stage
    IFS="$OLDIFS"
    { cmdname=$(echo "$suiteline" | cut -d' ' -f1)
      type -t "$cmdname" 1>/dev/null 2>&1 && {

        eval $suiteline || return
      } || {

        # Source script part or return
        sh_include $cmdname || return

        # Eval line now if we sourced a new function, otherwise continue
        type -t "$cmdname" >/dev/null 2>&1 || continue

        eval $suiteline
      }
    }
    close_stage "$suite_stage"
  done
  IFS="$OLDIFS"
  stage_id=script
}
# Id: U-S:                                                         ex:ft=bash:
