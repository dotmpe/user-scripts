#!/bin/sh

test -n "${U_S-}" -a -d "${U_S-}" || source "$(dirname -- "$0")/parts/env-0-u_s.sh"
test -d "$U_S" || return


test function = "$(type -t lib_load)" || {
  # Dev-Module for lib_loadXXX: cli wrapper, see init.sh
  . $U_S/src/sh/lib/lib.lib.sh
}

test -n "${default_lib-}" ||
  default_lib="os std sys str log shell stdio src main args match vc std-ht"

. $U_S/tools/sh/parts/lib_util.sh


# Main

# XXX: @Spec @Htd util-mode
# ext: external, sourced file gets to do everything. Here simply return.
# lib: set to try to load the default-lib required, but fail on missing envs
# boot: setup env, then load default-lib

case "$0" in

  "-"*|"" ) ;;

  * )

      test -n "${f_lib_load-}" && {
        # never
        echo "util.sh assert failed: f-lib-load is set ($0: $*)" >&2
        exit 1

      } || {

        # Set util_mode before sourcing util.sh to do anything else
        test -n "${util_mode-}" || util_mode=ext
      }

      # Return now for 'ext'
      test "$util_mode" = "ext" && return

      # XXX: for logger
      export scriptname base

      # Or either start given mode
      case "$util_mode" in
        boot|lib )
            lib_lib__load || return

      # Or return errstat on first unmatched case (or errors per step).
      esac || return

      case "$util_mode" in
        boot )
            lib_util_init || return ;;
      esac

      case "$util_mode" in
        boot|lib )
            lib_lib__init || return
            lib_load $default_lib || return ;;
      esac

      case "$util_mode" in
        boot )
            lib_init || return
            lib_util_deinit || return ;;
      esac
    ;;
esac

# Id: User-script/0.0.1-dev tools/sh/init-wrapper.sh
