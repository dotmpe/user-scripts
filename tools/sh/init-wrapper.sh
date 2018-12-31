#!/bin/sh

# Dev-Module for lib_loadXXX: cli wrapper, see init.sh

# Must be started from u-s project root or set before
#test -n "$scriptpath" || scriptpath="$(pwd -P)"
#test -n "$script_util" || script_util=$scriptpath/tools/sh

# XXX: +script-mpe cleanup . $U_S/src/sh/lib/lib.lib.sh
#. $script_util/init.sh
. $U_S/src/sh/lib/lib.lib.sh


lib_lib_load()
{
  test -n "$default_lib" ||
      default_lib="os std sys str log shell stdio src main argv match vc std-ht"
}

case "$0" in

  "-"*|"" ) ;;

  * )

      test -n "$f_lib_load" && {
        # never
        echo "util.sh assert failed: f-lib-load is set ($0: $*)" >&2
        exit 1

      } || {

        test -n "$__load_mode" || __load_mode=$__load
        case "$__load_mode" in

          # Setup SCRIPTPATH and include other scripts
          boot|main )
              util_boot "$@"
            ;;

        esac
      }
      test -n "$SCRIPTPATH" || {
        util_init
      }
      case "$__load_mode" in
        boot )
            lib_load
          ;;
        #ext|load-*|* ) ;; # External include, do nothing
      esac
    ;;
esac

# Id: user-script/0.0.1-dev tools/sh/util.sh
