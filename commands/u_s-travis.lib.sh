#!/bin/sh
travis_status()
{
  test -n "$1" || set -- "bvberkum/user-scripts" "$2"
  test -n "$2" || set -- "$1" "r0.0"

  #lib_load statusdir

  out=/tmp/u-s-travis-$2.svg
  curl -s 'https://api.travis-ci.org/'"$1"'.svg?branch='$2 >"$out"

  grep -q failing "$out" && r=1 || {
    grep -q error "$out" && r=2 || {
      r=0
    }
  }
  return $r
}
