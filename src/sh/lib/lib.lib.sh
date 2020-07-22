#!/bin/sh

# Module for lib_load


lib_lib_load()
{
  test -n "${default_lib-}" || default_lib="os sys str src shell"
  # XXX testing default_lib="argv match vc"
}

lib_lib_init()
{
  test -n "$LOG" -a \( -x "$LOG" -o "$(type -t "$LOG")" = "function" \) \
    && lib_lib_log="$LOG" || lib_lib_log="$INIT_LOG"
  test -n "$lib_lib_log" || return 108

  log_key=$scriptname/$$:u-s:\$1:lib:init \
    $lib_lib_log info "" "Loaded lib.lib" "$0"
}

lib_lib_log() { test -n "$LOG" && log="$LOG" || log="$lib_lib_log"; }

# Check if loaded or list all loaded libs
lib_loaded() # [Check-Libs...]
{
  test $# -gt 0 && {

    while test $# -gt 0
    do
      lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')

      test "$1" = "$(eval echo \$${lib_id}_lib_loaded)" || return
      shift
    done
    return

  } || {
    sh_genv '[a-z][a-z0-9]*_lib_loaded' | sed 's/_lib_loaded=0$//' | sort
  }
}

# Echoes if path exists. See sys.lib.sh lookup-exists
lib_exists() # Dir Name
{
  test -e "$1/$2.lib.sh" && echo "$1/$2.lib.sh"
}

# Echo every occurence of *.lib.sh on SCRIPTPATH
lib_path() # Local-Name Path-Var-Name
{
  test -n "${2-}" || set -- "$1" SCRIPTPATH
  lookup_test=${lookup_test:-"lib_exists"} lookup_path $2 "$1"
}

# Echo only first result for lib_path
lib_lookup() # Lib
{
  lib_path "$1" | head -n 1
}

# List matching names existing on path.
lib_glob() # Pattern ([Path-Var-Name]) ([paths]|paths-list|names|names-list)
{
  shopt -s nullglob
  lib_names() # Dir Pattern
  {
    echo "$1/"$2".lib.sh"
  }
  test -n "${1-}" || set -- "*" "${2-}" "${3-"paths"}"
  test -n "${2-}" || set -- "$1" "SCRIPTPATH" "${3-"paths"}"
  lookup_test=${lookup_test:-"lib_names"} lookup_path $2 "$1" | {
    case ${3-"paths"} in
      names ) tr -s ' ' '\n' | sed 's/^.*\/\([^\.]*\)\..*$/\1/' | tr '\n' ' ' ;;
      names-list ) tr -s ' ' '\n' | sed 's/^.*\/\([^\.]*\)\..*$/\1/' | tr '\n' ' ' | tr -s ' ' '\n' ;;
      paths ) tr -d '\n' ;;
      paths-list ) tr -d '\n' | tr -s ' ' '\n' ;;
      * ) return 2 ;;
    esac
  }
}

# List all libs in format (see lib-glob)
lib_list() # [Path-Var-Name] [Format]
{
  lib_glob "*" "${1-"SCRIPTPATH"}" "${2-"names-list"}"
}

# Lookup and load sh-lib on SCRIPTPATH
lib_load() # Libs...
{
  test -n "${1-}" || return 198
  test -n "${lib_lib_log-}" || return 108 # NOTE: sanity

  local log_key=$scriptname/$$:u-s:lib:load

  log_key=$log_key $lib_lib_log debug "" "Loading lib(s)" "$*"

  local lib_id f_lib_loaded f_lib_path r lookup_test=${lookup_test:-"lib_exists"}

  # __load_lib: true if inside util.sh:lib-load
  test -n "${__load_lib-}" || local __load_lib=1
  while test $# -gt 0
  do
    lib_id=$(printf -- "${1}" | tr -Cs '[:alnum:]_' '_')
    test -n "$lib_id" || {
      log_key=$log_key \
        $lib_lib_log error "" "err: lib_id=$lib_id" "" 1 || return
    }
    f_lib_loaded=$(eval printf -- \"\${${lib_id}_lib_loaded-}\")

    test "$f_lib_loaded" = "0" && {
      log_key=$log_key $lib_lib_log debug "" "Skipped loaded lib '$1'" ""
    } || {

        # Note: the equiv. code using sys.lib.sh is above, but since it may not
        # have been loaded yet keep it written out using plain shell.
        f_lib_path="$( echo "$SCRIPTPATH" | tr ':' '\n' | while read _PATH
          do
            $lookup_test "$_PATH" "$1" && {
              test ${lookup_first:-0} -eq 0 && break || continue
            } || continue
          done)"

        test -n "$f_lib_path" || {
          log_key=$log_key \
            $lib_lib_log error "" "No path for lib '$1'" "$SCRIPTPATH" 1 || return
        }

        log_key=$log_key $lib_lib_log debug "" "Loading lib '$1'" ""
        test ${lookup_first:-0} -eq 0 && {

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
        type ${lib_id}_lib_load  2> /dev/null 1> /dev/null && {

          ${lib_id}_lib_load || { r=$?;
            eval ${lib_id}_lib_loaded=$r
            log_key=$log_key \
              $lib_lib_log error "" "in lib-load $1 ($r)" "$f_lib_path"
            return $r
          }
        } || true

        eval ${lib_id}_lib_loaded=0
        eval "LIB_SRC=\"${LIB_SRC-} $f_lib_path\""
        lib_loaded="${lib_loaded-} $lib_id"
        # FIXME sep. profile/front-end for shell vs user-scripts
        # $lib_lib_log info "$scriptname:lib" "Finished loading ${lib_id}: OK"
        unset lib_id
    }
    shift
  done
}

# Verify lib was loaded or bail out
lib_assert() # Libs...
{
  local log_key=$scriptname/$$:u-s:lib:assert
  test $# -gt 0 || return
  while test $# -gt 0
  do
    mkvid "$1"
    test "$(eval "echo \$${vid}_lib_loaded" 2>/dev/null )" = "0" || {
      log_key=$log_key $lib_lib_log error "" "Assert loaded '$1'" "" 1
      return 1
    }
    shift
  done
}

# After loaded, execute <lib-id>_lib_init() if defined for each lib in load seq.
lib_init()
{
  test $# -gt 0 || set -- $lib_loaded
  local log_key=$scriptname/$$:u-s:lib:init
  log_key=$log_key $lib_lib_log info "" "Init libs '$*'" ""

  # TODO: init only once, set <libid>_lib_init=...
  while test $# -gt 0
  do
    type ${1}_lib_init 2> /dev/null 1> /dev/null && {
      ${1}_lib_init || { r=$?
        log_key=$log_key $lib_lib_log error "" "in lib-init $1 ($r)" "" 1
        return $r
      }
      eval ${1}_lib_init=0
    }
    shift
  done
}

# TODO: lib-unload
#lib_unload() See COMPO:c-lib-reset
#{
#}

lib_require() # Libs...
{
  test -z "${__load_lib-}" || {
    LIB_REQ="${LIB_REQ:-}$* "
    return
  }
  test -z "${1-}" || lib_load "$@" || return
  test -n "${LIB_REQ-}" || return 0
  until test -z "${LIB_REQ-}"
  do
    set -- $LIB_REQ ; unset LIB_REQ
    lib_load "$@"
  done
}

# Id: U-S:src/sh/lib/lib.lib.sh                                   vim:ft=bash:
