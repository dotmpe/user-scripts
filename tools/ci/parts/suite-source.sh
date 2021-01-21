#!/usr/bin/env bash

suite_source () # Tab Col [Prefix]
{
  test $# -ge 2 -a -f "${1:-}" -a $# -le 3 || return 98

  sh_include $( suite_from_table "$1" Parts "$2" "${3:-}" )
}
# Id: U-S:                                                         ex:ft=bash:
