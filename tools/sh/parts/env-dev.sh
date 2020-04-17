#!/usr/bin/env bash

# XXX: test -n "$U_S" -a -d "$U_S" || source ./tools/sh/parts/env-0-u_s.sh
export U_S="${U_S:="$CWD"}" # No-Sync

: "${hostname:="`hostname -s`"}"

: "${sh_src_base:="/src/sh/lib"}"
: "${sh_util_base:="/tools/sh"}"
: "${ci_util_base:="/tools/ci"}"

: "${userscript:="$U_S"}"

# Define now, Set/use later
: "${SCRIPTPATH:=""}"
: "${default_lib:=""}"
: "${init_sh_libs:=""}"
: "${LIB_SRC:=""}"

: "${CWD:="$PWD"}"
: "${sh_tools:="$CWD$sh_util_base"}"
: "${ci_tools:="$CWD$ci_util_base"}"

type sh_include >/dev/null 2>&1 || {
  . "$U_S/tools/sh/parts/include.sh" || return
}

sh_include unique-paths

# XXX . "$sh_tools/parts/env-init-log.sh"
sh_include env-0-src env-std env-ucache || return

# XXX: remove from env; TODO: disable undefined check during init.sh,
# or when dealing with other dynamic env..

: "${__load_lib:=""}"
: "${lib_loaded:=""}"

sh_include env-0-1-lib-sys env-0-2-lib-os env-0-3-lib-str env-0-4-lib-script ||
  return

: "${init_sh_boot:=""}"

sh_include env-0-5-lib-log env-0-6-lib-git env-0-7-lib-vc ||
  return

sh_include exec || return

: "${TMPDIR:=/tmp}"
: "${RAM_TMPDIR:=}"
