#!/bin/sh

## Echo lines in suite

suite_from_table () # ~ <Table> <Name-Column> <Order-Column> <Order-Prefix>
{
  test $# -ge 3 -a $# -le 4 || return 98
  test -f "${1:-}" || $LOG error "" "Expected table" "PWD=$PWD 1=$1" 98

  local tab="$1" name="$2" order="$3" pref=${4:-}; shift
  local parts_w= offset= end=

  eval $( hd_offsets "$tab" "$name" ) ; name_c=$offset name_w=$end
  eval $( hd_offsets "$tab" "$order" )

  {
    $ggrep -v '^\s*\(#.*\)\?$' "$tab" |
      $gcut -c$name_c-$name_w,$offset-$end |
      $ggrep '\ '"$pref"'[0-9]*\s*$' || {
        $LOG "error" "" "No steps at $order:$pref" "" 1
        return 1
      }
  } | $gsort -n -k1.$(( 1 + $name_w )) |
      $gsed -E 's/\s+[0-9]+\s*$//g'
}
# Id: U-S:                                                         ex:ft=bash:
