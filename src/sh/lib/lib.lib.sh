#!/bin/sh

## Load User-Script modules

# Load other libraries from SCRIPTPATH, and execute hooks on-load and init.

# TODO: consolidate +User-conf lib-load scripts


lib_lib__load()
{
  stderr echo lib.lib:load: Deprecated $(caller): $(caller 1)
  test -n "${default_lib-}" || default_lib="os sys str src shell"
  #lib_groups \
  #  base/lib-{path,load,init} \
  #  core/{:base,lib-{assert,require}}
}

lib_lib__init()
{
  init_lib_log lib_lib  || return
  $lib_lib_log info ":lib-init" "Loaded lib.lib" "$0"
}

lib_lib__group__base={lib-{path,load,init}}
lib_lib__group__core={:base,lib-{assert,require}}


# Verify lib was loaded or bail out
lib_assert() # Libs...
{
  local log_key=${scriptname:-$0}/$$:u-s:lib:assert
  test $# -gt 0 || return 98
  while test $# -gt 0
  do
    mkvid "$1"
    test "$(eval "echo \$${vid}_lib_load" 2>/dev/null )" = "0" || {
      log_key=$log_key $lib_lib_log error "" "Assert loaded '$1'" "" 1
      return 1
    }
    shift
  done
}

lib_errors ()
{
  local r=0
  set -- $(sh_env | grep '_lib_load=[^0]' | sed 's/_lib_load=.*//' )
  test -z "$*" || {
      $LOG warn "" "Lib-load problems" "$*"; r=1
  }
  set -- $(sh_env | grep '_lib_init=[^0]' | sed 's/_lib_init=.*//' )
  test -z "$*" || {
      $LOG warn "" "Lib-init problems" "$*"; r=1
  }
  return $r
}

# Echoes if path exists. See sys.lib.sh lookup-exists
lib_exists () # [lookup_first=true] ~ <Lib-name> [<Dirs...>]
{
  local name="$1" r=1
  shift
  test $# -gt 0 || set -- $(echo "$SCRIPTPATH" | tr ':' '\n')
  while test $# -gt 0
  do
    test -e "$1/$name.lib.sh" && {
      echo "$1/$name.lib.sh"
      ${lookup_first:-true} && return || r=0
    }
    shift
  done
  return $r
}

# List matching names existing on path.
lib_glob () # Pattern ([Path-Var-Name]) ([paths]|paths-list|names|names-list)
{
  test $# -le 3 || return 98
  shopt -s nullglob
  lib_glob_names() # Dir Pattern                                    sh:no-stat
  {
    echo "$2/"$1".lib.sh"
  }
  test -n "${1-}" || set -- "*" "${2-}" "${3-"paths"}"
  test -n "${2-}" || set -- "$1" "SCRIPTPATH" "${3-"paths"}"
  lookup_test=${lookup_test:-"lib_glob_names"}  \
  lookup_first=${lookup_first:-false} lookup_path $2 "$1" | grep -v '^\s*$' | {
    case ${3-"paths"} in
      names ) tr -s ' ' '\n' | sed 's/^.*\/\([^\.]*\)\..*$/\1/' | tr -s '\n ' ' ' ;;
      names-list|name-list ) tr -s '\n ' '\n' | sed 's/^.*\/\([^\.]*\)\..*$/\1/' | tr -s '\n ' ' ' | tr -s ' ' '\n' ;;
      paths ) tr -s '\n ' ' ';;
      paths-list|path-list|list ) tr -s '\n ' '\n' ;;
      * ) return 2 ;;
    esac
  }
}

# Find libs by content regex, list paths in format (see lib-glob for formats)
lib_grep() # grep_f=-Hni ~ Regex [Name-Glob [Path-Var-Name]]
{
  test $# -gt 0 -a -n "${1-}" || return 98
  lib_glob "${2:-"*"}" ${3:-"SCRIPTPATH"} "paths-list" | {
    test -n "${grep_f-}" || local grep_f=-Hni
    ( set +euo pipefail
      act="grep $grep_f '$1'" foreach_eval || true )
  }
}

# After load, execute <lib-id>_lib_init() if defined for each lib in load seq.
lib_init () # ~ [<Lib-names...>]
{
  test $# -gt 0 || set -- ${lib_loaded:?}
  local log_key=${scriptname:-$0}/$$:u-s:lib:init
  log_key=$log_key $lib_lib_log info "" "Init libs '$*'" ""

  # TODO: init only once, set <libid>_lib_init=...
  while test $# -gt 0
  do
    lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')
    type ${lib_id}_lib__init 2> /dev/null 1> /dev/null && {
      ${lib_id}_lib__init || { r=$?
        log_key=$log_key $lib_lib_log error "" "in lib-init $1 ($r)" "" 1
        return $r
      }
      eval ${lib_id}_lib_init=0
    }
    shift
  done
}

# List all paths or names for libs (see lib-glob for formats)
lib_list () # ~ [<Path-Var-name>] [<Format-key>]
{
  test $# -le 2 || return 98
  lib_glob "*" "${1:-"SCRIPTPATH"}" "${2:-"names-list"}"
}

lib_load () # ~ <Lib-names...> # Lookup and load sh-lib on SCRIPTPATH
{
  test -n "${1-}" || return 190
  test -n "${lib_lib_log-}" || return 108 # NOTE: sanity

  local lib_loading=true log_key=${scriptname:-$0}/$$:u-s:lib:load

  log_key=$log_key $lib_lib_log debug "" "Loading lib(s)" "$*"

  local lib_id f_lib_loaded f_lib_path r lookup_test=${lookup_test:-"lib_exists"}

  # lib_load: true if inside util.sh:lib-load
  test -n "${lib_load-}" || local lib_load=1
  while test $# -gt 0
  do
    lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')
    test -n "$lib_id" || {
      log_key=$log_key \
        $lib_lib_log error "" "err: lib_id=$lib_id" "" 1 || return
    }
    f_lib_loaded=$(eval printf -- \"\${${lib_id}_lib_load-}\")

    test "$f_lib_loaded" = "0" && {
      log_key=$log_key $lib_lib_log debug "" "Skipped loaded lib '$1'" ""
    } || {

        # Note: the equiv. code using sys.lib.sh is above, but since it may not
        # have been loaded yet keep it written out using plain shell.
        f_lib_path="$( echo "$SCRIPTPATH" | tr ':' '\n' | while read _PATH
          do
            $lookup_test "$1" "$_PATH" && {
              ! ${lookup_first:-false} && break || continue
            } || continue
          done)"

        test -n "$f_lib_path" || {
          log_key=$log_key \
            $lib_lib_log error "" "No path for lib '$1'" "$SCRIPTPATH" 1 || return
        }

        log_key=$log_key $lib_lib_log debug "" "Loading lib '$1'" ""
        ! ${lookup_first:-false} && {

          . "$f_lib_path" || { r=$?; lib_src_stat=$r
            log_key=$log_key \
              $lib_lib_log error "" "sourcing $1 ($r)" "$f_lib_path" 1
            return $lib_src_stat
          }

        } || {

          for f_lib_path_ in $f_lib_path
          do
            . "$f_lib_path_" || { r=$?; lib_src_stat=$r
              log_key=$log_key \
                $lib_lib_log error "" "sourcing $1 ($r)" "$f_lib_path_" 1
              return $lib_src_stat
            }
          done
        }

        # like func_exists is in sys.lib.sh. But inline here:
        type ${lib_id}_lib__load  2> /dev/null 1> /dev/null && {

          ${lib_id}_lib__load || { r=$?;
            eval ${lib_id}_lib_load=$r
            log_key=$log_key \
              $lib_lib_log error "" "in lib-load $1 ($r)" "$f_lib_path"
            return $r
          }
        } || true

        eval ${lib_id}_lib_load=0
        eval "LIB_SRC=\"${LIB_SRC-}${LIB_SRC:+ }$f_lib_path\""
        lib_loaded="${lib_loaded-}${lib_loaded:+ }$1"
        # FIXME sep. profile/front-end for shell vs user-scripts
        # $lib_lib_log info "${scriptname:-$0}:lib" "Finished loading ${lib_id}: OK"
        unset lib_id
    }
    shift
  done
}

lib_loaded () # ~ [<Lib-ids...>] # Check wether given are loaded or list loaded
{
  test $# -gt 0 && {
    # Check given
    lib_loaded_env_ids "$@"
    return $?
  }
  # List all
  foreach $lib_loaded
}

# Check if loaded or list all loaded libs
lib_loaded_env_ids() # [Check-Libs...]
{
  test $# -gt 0 && {

    while test $# -gt 0
    do
      lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')

      test "$1" = "$(eval echo \${${lib_id}_lib_load-})" || return
      shift
    done
    return

  } || {
    # List all
    sh_genv '[a-z][a-z0-9_]*_lib_load' | sed 's/_lib_load=0$//'
  }
}

lib_lookup () # ~ <Lib-name> # Echo only first result for lib_path
{
  lookup_first=true lib_path "$1"
}

# Echo every occurence of *.lib.sh on SCRIPTPATH
lib_path () # ~ <Local-name> [<Path-Var-name>]
{
  test $# -le 2 || return 98
  test -n "${2-}" || set -- "$1" SCRIPTPATH
  lookup_test=${lookup_test:-"lib_exists"} \
  lookup_first=${lookup_first:-false} \
    lookup_path $2 "${1:?}"
}

lib_paths () # (s?) ~ [<Lib-names...>]
{
  act=lib_path foreach_do "$@"
}

# TODO: Call *_lib_unload and unset loaded var. See also reload. #lib-unload
# See COMPO:c-lib-reset
lib_unload() # [Libs...]
{
  test $# -gt 0 || set -- $lib_loaded

  local log_key=${scriptname:-$0}/$$:u-s:lib:unload
  log_key=$log_key $lib_lib_log debug "" "Unloading lib(s)" "$*"

  local lib_id r
  while test $# -gt 0
    do lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')
      type ${lib_id}_lib_unload  2> /dev/null 1> /dev/null && {

        ${lib_id}_lib_unload || { r=$?;
          log_key=$log_key \
            $lib_lib_log error "" "in lib-unload $1 ($r)" "$f_lib_path"
          return $r
        }
      } || true
      unset ${lib_id}_lib_load
      shift
    done
}

# Reload given or already loaded libraries. NOTE: this does not cleanup
# $lib_loaded, eg. cleanup afterwards:
# lib_loaded=$(foreach "$lib_loaded" | remove_dupes | lines_to_words)
lib_reload() # [Libs...]
{
  test $# -gt 0 || set -- $lib_loaded

  local log_key=${scriptname:-$0}/$$:u-s:lib:reload
  log_key=$log_key $lib_lib_log debug "" "Reloading lib(s)" "$*"

  unset  $( while test $# -gt 0
    do lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')
      echo ${lib_id}_lib_load
      shift
    done )

  lib_require "$@"
}

# To clean-up lib-loaded after reloading, it is easier than to filter
# modules out on reloading, and I don't think lib_load should make an
# exception. This can also sort, with no arguments the default is '-d -u' ie.
# dictionary order and unique lines.
lib_loaded_cleanup () # [Sort-Opts]
{
  test $# -eq 0 &&  {
# Remove duplicates without changing sort order
    lib_loaded=$(echo $(echo $lib_loaded | tr ' ' '\n' | awk '!a[$0]++'))
  } || {
    test -n "$1" || set -- '-u -d'
    lib_loaded=$(echo $(echo $lib_loaded | tr ' ' '\n' | sort $1 ))
  }
}

# Load given libs or put in LIB_REQ if called from lib-load already. If put in
# a lib load hook this does not recurse a call to lib-load but appends to a
# global variable
# It then keep loading libs until LIB-REQ is empty.
#
# FIXME: return pending error status
# TODO: run over lib-require within lib init hook the same way, or define any
# sequence of hooks to run if present as well.
# TODO: lib-require str/fnmatch sys/core subgroups... and alternatives?
#
lib_require () # ~ <Libs...> # Load all libs, including those from lib-require in load
{
  test $# -gt 0 || return ${_E_MA:-194}
  test -z "${load_lib-}" || {
    LIB_REQ="${LIB_REQ:-}$* "
    return
  }
  lib_load "$@" || return
  test -z "${LIB_REQ-}" && return
  until test -z "${LIB_REQ-}"
  do
    set -- $LIB_REQ ; unset LIB_REQ
    lib_load "$@"
  done
}

# Id: U-S:src/sh/lib/lib.lib.sh                                   vim:ft=bash:
