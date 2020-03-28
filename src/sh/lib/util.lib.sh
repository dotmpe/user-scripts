#!/bin/sh

util_lib_load()
{
  true
}

util_lib_init()
{
  test -n "${LOG-}" || return 102
}



# Main

case "$0" in "-"* ) ;; * )

  set -e

  test -n "$scriptname" || scriptname="$(basename -- "$0" .sh)"
  test -n "$verbosity" || verbosity=5
  test -z "$__load_lib" && lib_util_act="$1" || lib_util_act="load-ext"
  case "$lib_util_act" in

    load-ext ) ;; # External include, do nothing

    load )
        test -n "$scriptpath" || scriptpath="$(dirname "$0")/script"
        lib_load || {
          echo "Error loading $scriptname" 1>&2
          exit 1
        }
      ;;

    '' ) ;;

    * ) # Setup SCRIPTPATH and include other scripts
        echo "Ignored $scriptname argument(s) $0: $*" 1>&2
      ;;

  esac

;; esac

# Id: user-conf/0.0.1-dev script/util.lib.sh
# Sync: BIN:tools/sh/init-wrapper.sh
