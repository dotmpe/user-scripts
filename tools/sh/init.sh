#!/bin/sh

# This is for sourcing into a standalone or other env boot/init script (ie. CI)

# U_S=<...> . <sh_tools>/init.sh

# It requires a path to the basedir of the project to boot with. Containing:
# - U_S ?= $PWD
# - sh_src_base ?= /src/sh/lib
# - SCRIPTPATH %%= $U_S/$sh_src_base
# - sh_tools ?= $U_S/tools/sh

# It cannot determine the path to the init.sh, but instead setups like above.
# In addition, it takes these envs to select libs and boot script:

# init_sh_libs ?= sys os str
# init_sh_boot ?= stderr-console-logger

test -n "${CWD-}" || CWD="$PWD"
test -n "${LOG-}" -a -x "${LOG-}" -o \
  "$(type -t "${LOG:-}" 2>/dev/null )" = "function" &&
  LOG_ENV=1 INIT_LOG=$LOG || LOG_ENV=0 INIT_LOG=$CWD/tools/sh/log.sh
# Sh-Sync: tools/sh/parts/env-init-log.sh

# Must be set after U-s:load
test -n "${U_S-}" -a -d "${U_S-}" || . $CWD/tools/sh/parts/env-0-u_s.sh

# Must be started from script-package, or provide SCRIPTPATH
test -n "${SCRIPTPATH-}" || . $U_S/tools/sh/parts/env-scriptpath-deps.sh

test -n "${U_S-}" -a -d "${U_S-}" || $LOG "error" "" "Missing U-s" "$U_S" 1

test -n "${sh_src_base-}" || sh_src_base=/src/sh/lib
test -n "${u_s_lib-}" || u_s_lib="$U_S$sh_src_base"
test -n "${scriptname-}" || scriptname="`basename -- "$0"`"
test -n "${sh_tools-}" || sh_tools="$U_S/tools/sh"

# Now include module with `lib_load`
test -z "${DEBUG-}" || echo . $u_s_lib/lib.lib.sh >&2
{
  . $u_s_lib/lib.lib.sh || return $?
  lib_lib_load && lib_lib_loaded=0 || return $?
  lib_lib_init
} ||
  $INIT_LOG "error" "$scriptname:init.sh" "Failed at lib.lib $?" "" 1

test -n "${LOG-}" || LOG=$INIT_LOG

# And conclude with logger setup but possibly do other script-util bootstraps.

test "${init_sh_libs-}" = "0" || {
  test "${init_sh_libs:-1}" != "1" ||
    init_sh_libs=sys\ os\ str\ script\ log\ shell

  $INIT_LOG "info" "$scriptname:sh:init" "Loading" "$init_sh_libs"

  type sh_include >/dev/null 2>&1 || . "$U_S/tools/sh/parts/include.sh"

  lib_load $init_sh_libs || {
    $INIT_LOG "error" "$scriptname:init.sh" "Failed loading libs: $?" "$init_sh_libs"
    return 1
  }

  lib_init $init_sh_libs || {
    $INIT_LOG "error" "$scriptname:init.sh" "Failed init'ing libs: $?" "$init_sh_libs"
    return 1
  }
}

test "$(type -f scripts_init 2>/dev/null)" = function && {
  test "${init_sh_boot:-}" != "0" || init_sh_boot=null
  test "${init_sh_boot:-1}" != "1" || init_sh_boot=stderr-console-logger

  test -z "${DEBUG-}" || echo sh_tools=$sh_tools scripts_init $init_sh_boot >&2
  scripts_init $init_sh_boot || {
    $INIT_LOG "error" "$scriptname:init.sh" "Failed at bootstrap '$init_sh_boot'" $? 1
    return 1
  }

} ||
  test -z "${init_sh_boot-}" &&
    $INIT_LOG "debug" "$scriptname:init.sh" "No default scripts-init" ||
    $INIT_LOG "warn" "$scriptname:init.sh" "Ignored init.sh:boot because no scripts-init" "init.sh:boot=$init_sh_boot"

# XXX: end init-phase: test -n "$LOG_ENV" && unset LOG_ENV INIT_LOG || unset LOG_ENV INIT_LOG LOG

# Id: user-scripts/0.0.0-dev tools/sh/init.sh
