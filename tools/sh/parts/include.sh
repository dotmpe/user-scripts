#!/usr/bin/env bash


# Show path after resolving inlcude part
sh_include_path()
{
  sh_include_dry=1 sh_include "$@"
}

# List all paths with include parts
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

# Default sh-include path basedirs
sh_include_path_basedirs () # ~
{
  test "$CWD" = "$(cd $U_S && pwd -P)" && echo "$CWD" || echo "$CWD $U_S"
}

sh_include_path_dirs () # (sh-include:) ~ <Basedirs...> # Output sh-include lookup path list
{
  local basedir subdir

  test $# -gt 0 -a -n "${1:-}" ||
    set -- ${sh_include_path_basedirs:-$(sh_include_path_basedirs)}

  for basedir in "$@"
  do
    for subdir in ${sh_include_path_subdirs:-$( sh_include_path_subdirs )}
    do
      test -e "$basedir/$subdir" || continue
      echo $basedir/$subdir
    done
  done
}

#alias sh-parts=sh_include

# Include file by name-id from from $PWD/tools and other tools directories.
# By default sets sh_include_suites=ci,sh and sh_include_path=$PWD,$U_S.
sh_include () # ~ <Partnames...> # Source first existing
{
  test $# -gt 0 || return 64

  test -n "${LOG-}" || local LOG=print_err

  test -n "${sh_include_path:-}" || {
    local sh_include_path
    sh_include_path="$( sh_include_path_dirs | tr '\n' ' ')"
  }

  local sh_include_partid sh_include_base sh_include_part_var

  for sh_include_partid in $*
  do
    sh_include_part_var=sh_include_part_${sh_include_partid//-/_}
    # test ${!sh_include_part_var:-1} -eq 0 && continue

    test -z "${sh_include_debug:-}" ||
      $LOG info "" "looking for $sh_include_partid at" "$sh_include_path"
    for sh_include_base in $sh_include_path
    do test -e "$sh_include_base/$sh_include_partid.sh" && break || continue
    done

    test -e "$sh_include_base/$sh_include_partid.sh" || {
      $LOG error "" "no sh_include $sh_include_partid" "$CWD $?: $sh_include_path"
      return 1
    }

    test -n "${sh_include_dry:-}" && {
      echo "$sh_include_base/$sh_include_partid.sh"
    } || {
      # DEBUG "\e[30m# START $sh_include_base/$sh_include_partid.sh\e[0m\n" >&2
      . "$sh_include_base/$sh_include_partid.sh" && {
        declare -g "${sh_include_part_var}=0"
      } || {
        declare -g "${sh_include_part_var}=$?"
        $LOG error "" "at sh_include $sh_include_partid" "$?"
      }
      # DEBUG "\e[30m# STOP $sh_include_base/$sh_include_partid.sh\e[0m\n" >&2
    }
  done
}

sh_require () # ~ <Partnames...> # ~ Test each part was sourced with zero-status
{
  test $# -gt 0 || return 64

  test -n "${LOG-}" || local LOG=print_err
  test -n "${stat-}" || local stat=exit #return

  local sh_include_partid sh_include_part_var

  for sh_include_partid in "$@"
  do
    sh_include_part_var=sh_include_part_${sh_include_partid//-/_}
    test ${!sh_include_part_var:-1} -eq 0 ||
      $LOG error "" "Missing sh-include" "$sh_include_partid" 1
  done || $stat 1
}

# XXX: sh-include-run <Cmd-fun-name> [<Part-name>]
sh_run ()
{
  local -r vid=$(str_word "${1:?}")
  #local vid=${1:?}
  #str_vword vid
  local lk=${lk-}:sh-run:$vid
  func_exists "$vid" || {
    sh_include "${2:-$1}" ||
      $LOG error "$lk" "Failed to find impl" "E127($?):$1" 127 || return

    func_exists "$vid" ||
      $LOG error "$lk" "Failed to get sh impl" "E3($?):$vid:$1" 3 || return
  }

  "$vid" || $LOG "$lk" "Non-zero sh-run status" "E$?:$1" $?
}

# Id: U-S:
