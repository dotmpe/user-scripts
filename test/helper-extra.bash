#!/bin/bash

fnmatch()
{
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
}

tmpf()
{
  tmpd || return $?
  tmpf=$tmpd/$BATS_TEST_NAME-$BATS_TEST_NUMBER
  test -z "$1" || tmpf="$tmpf-$1"
}

tmpd()
{
  tmpd=$BATS_TMPDIR/bats-tempd-$(get_uuid)
  test ! -d "$tmpd" || return
  mkdir -vp "$tmpd"
}
