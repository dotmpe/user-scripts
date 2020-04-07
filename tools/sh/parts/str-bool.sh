#!/bin/sh


# Error unless non-empty and trueish
trueish()
{
  test $# -eq 1 -a -n "${1:-}" || return
  case "$1" in
    [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1 )
      return 0;;
    * )
      return 1;;
  esac
}
# Sh-Copy: HT:tools/u-s/parts/trueish.inc.sh
# Sh-Copy-Part: U-S:src/sh/lib/sys.lib.sh

# Error unless non-empty and falseish
falseish()
{
  test $# -eq 1 -a -n "${1:-}" || return
  case "$1" in
    [Oo]ff|[Ff]alse|[Nn]|[Nn]o|0)
      return 0;;
    * )
      return 1;;
  esac
}
# Sh-Copy-Part: U-S:src/sh/lib/sys.lib.sh

# Error unless empty or falseish
not_trueish()
{
  test $# -eq 1 -a -n "${1:-}" || return 0
  falseish "$1"
}

# Error unless empty or trueish
not_falseish()
{
  test $# -eq 1 -a -n "${1:-}" || return 0
  trueish "$1"
}
