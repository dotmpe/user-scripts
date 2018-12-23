#!/bin/ash

: "${ci_stages:=}"

export_stage() {
  test -n "$1" || return 100
  test -n "$2" || set -- "$1" "$1"

  export scriptname=$1 stage=$1 stage_id=$2 ${2}_ts="$($gdate +%s.%N)"
  ci_stages="$ci_stages $stage_id"
}

announce_stage() {
  test -n "$1" || set -- "$stage"
  test -n "$2" || set -- "$1" "$stage_id"
  test -n "$2" || set -- "$1" "$1"

  print_yellow "$stage" "Starting stage... ($($gdate --iso=ns -d @$(eval echo \$${2}_ts)))"
}

close_stage()
{
  test -n "$1" || set -- "Done"

  export ${stage_id}_end_ts="$($gdate +%s.%N)"
  stages_done="$stages_done $stage_id"
  print_yellow "$stage" "$1 ($($gdate --iso=ns))"
}

announce()
{
  print_yellow "$stage" "$1 ($($gdate --iso=ns))"
}


fnmatch() { case "$2" in $1 ) return ;; * ) return 1 ;; esac; }

assert_nonzero()
{
  test $# -gt 0 && test -n "$1"
}


. "${script_util:-"$CWD/tools/sh"}/parts/print-color.sh"

. "${print_color:="tools/ci/parts/std-runner.sh"}"
. "${print_color:="tools/ci/parts/std-reporter.sh"}"

print_yellow "ci:util" "Loaded"

#
