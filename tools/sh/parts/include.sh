#!/usr/bin/env bash


sh_include_path()
{
  sh_include_dry=1 sh_include "$@"
}


# Include file by name-id from from $PWD/tools and other tools directories.
# By default sets sh_include_suites=ci,sh and sh_include_path=$PWD,$U_S.
sh_include() # Parts...
{
  test $# -gt 0 || return

  local sh_include_partid sh_include_base

  test -n "${sh_include_subdirs:-}" || {
    local sh_include_subdirs
    true "${sh_include_suites:=ci,sh}"
    sh_include_subdirs="tools/{$sh_include_suites}/{parts,boot}"
  }

  test -n "${sh_include_path:-}" || {
    local sh_include_path
    test "$(pwd -P)" = "$(cd $U_S && pwd -P)" &&
      sh_include_path="$(eval echo "$U_S/$sh_include_subdirs")" ||
      sh_include_path="$(eval echo "{$PWD,$U_S}/$sh_include_subdirs")"
  }

  for sh_include_partid in $*
  do
    for sh_include_base in $sh_include_path
    do test -e "$sh_include_base/$sh_include_partid.sh" && break || continue
    done
    test -e "$sh_include_base/$sh_include_partid.sh" || {
      type print_err
      print_err error "" "no sh_include $sh_include_partid" "$?"
      return 1
    }

    test -n "${sh_include_dry:-}" &&
      echo "sh-include $sh_include_base/$sh_include_partid.sh" || {
        sh_include_path= \
        . "$sh_include_base/$sh_include_partid.sh" || {
          print_err error "" "at sh_include $sh_include_partid" "$?" $?
      }
    }
  done

}

# Id: U-S:
