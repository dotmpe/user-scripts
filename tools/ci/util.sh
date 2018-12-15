#!/bin/sh

export_stage() {
  test -n "$2" || set -- "$1" "$1"
  echo scriptname=$1 stage=$1  ${2}_ts="$(date +%s.%N)"
  export scriptname=$1 stage=$1  ${2}_ts="$(date +%s.%N)"
}
announce_stage() {
  test -n "$1" || set -- "$stage"
  echo stage=$stage
  echo "--- Starting '$stage'... ($(date --iso=ns -d @$(eval echo \$${1}_ts)))"
}
announce()
{
  echo "---------- $1 ($(date --iso=ns -d @$(eval echo \$${1}_ts)))"
}
