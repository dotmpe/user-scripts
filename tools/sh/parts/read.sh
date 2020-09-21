#!/bin/sh

# Read file filtering octothorp comments and empty lines
sh_read () # ( FILE | - )
{
  test $# -gt 0 -a $# -le 2 || return 98
  test -n "$1" -a -e "$1" || return 97
  test -n "${2:-}" || set -- "$1" '^\s*(#.*|\s*)$'
  {
    test -z "${cat_f:-}" && {
      grep -Ev "$2" "$1" || return 1
    } || {
      cat $cat_f "$1" | grep -Ev "$2" || return 1
    }
  } | sed 's/\ \#.*$//' # Strip trailing comments
}
# Sh-Copy: read_nix_style_file
