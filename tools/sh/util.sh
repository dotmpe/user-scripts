#!/usr/bin/env bash
test -z "${sh_util_:-}" && sh_util_=1 || return 198 # Recursion


assert_nonzero()
{
  test $# -gt 0 && test -n "$1"
}

. $sh_tools/init-include.sh # Initialize sh_include

sh_include \
  str-bool str-id read exec \
  unique-paths hd-offsets suite-from-table suite-source suite-run \
  env-0-1-lib-sys print-color
#  remove-dupes unique-paths
#  env-0-src

# Id: U-S:
