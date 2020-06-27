#!/usr/bin/env bash


sh_include_path()
{
  sh_include_dry=1 sh_include "$@"
}

sh_include_path_subdirs()
{
  local lang suite langs suites
  langs="${sh_include_path_langs:-"main ci bash sh"}"
  suites="${sh_include_path_suites:-"boot parts"}"

  for lang in $langs
  do
    for suite in $suites
    do
      echo "tools/$lang/$suite"
    done
  done
}

sh_include_path_dirs()
{
  local basedir subdir

  test $# -gt 0 || {
    test "$CWD" = "$(cd $U_S && pwd -P)" &&
      set -- "$CWD" || set -- "$CWD" "$U_S"
  }

  for basedir in "$@"
  do
    for subdir in $sh_include_path_subdirs
    do
      test -e "$basedir/$subdir" || continue
      echo $basedir/$subdir
    done
  done
}

# Include file by name-id from from $PWD/tools and other tools directories.
# By default sets sh_include_suites=ci,sh and sh_include_path=$PWD,$U_S.
sh_include() # Parts...
{
  test $# -gt 0 || return

  test -n "${sh_include_path_subdirs:-}" || {
    local sh_include_path_subdirs
    sh_include_path_subdirs="$( sh_include_path_subdirs )"
  }

  test -n "${sh_include_path:-}" || {
    local sh_include_path
    sh_include_path_dirs="$( sh_include_path_dirs ${sh_include_path_basedirs:-} )"
  }

  local sh_include_partid sh_include_base

  for sh_include_partid in $*
  do
    test -z "${sh_include_debug:-}" ||
      print_err info "" "looking for $sh_include_partid at" "$sh_include_path"
    for sh_include_base in $sh_include_path_dirs
    do test -e "$sh_include_base/$sh_include_partid.sh" && break || continue
    done

    test -e "$sh_include_base/$sh_include_partid.sh" || {
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
