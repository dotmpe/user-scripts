#!/usr/bin/env bash

sh_include() # Parts...
{
  local sh_include_part base
  test $# -gt 0 || return
  true ${ci_tools:=tools/ci}
  true ${sh_tools:=tools/sh}
  test -n "${sh_include_path:-}" || local sh_include_path
  true ${sh_include_path:="{$ci_tools,$sh_tools,$U_S/tools/{ci,sh}}/{parts,boot}"} || return 112

  for sh_include_part in $*
  do
    for base in $(eval echo $sh_include_path)
    do test -e "$base/$sh_include_part.sh" && break || continue
    done

    test -e "$base/$sh_include_part.sh" || {
      print_err error "" "no sh_include $sh_include_part" "$?" 1
    }

    sh_include_path= \
    . "$base/$sh_include_part.sh" || {
      print_err error "" "at sh_include $sh_include_part" "$?" $?
    }
  done

}

# Id: U-S:
