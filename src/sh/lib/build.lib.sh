#!/bin/sh

build_tests()
{
  local test_fmt=$1 report_fmt=$2; shift 2

  for x in "$@"
    do
      echo "$(dirname $x)/$(basename -- "$x" .$test_fmt).$report_fmt"
    done
}

build_test()
{
  true
}

build()
{
  test -n "$package_build_tool" || return 1
  $package_build_tool "$@"
}
