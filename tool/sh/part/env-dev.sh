#!/usr/bin/env bash

# XXX: test -n "$U_S" -a -d "$U_S" || source ./tool/sh/parts/env-0-u_s.sh
export U_S="${U_S:="$CWD"}" # No-Sync

: "${hostname:="`hostname -s`"}"

: "${sh_src_base:="/src/sh/lib"}"
: "${sh_util_base:="/tool/sh"}"
: "${ci_util_base:="/tool/ci"}"

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
  . "$U_S/tool/sh/parts/include.sh" || return
}

# XXX . "$sh_tools/parts/env-init-log.sh"
sh_include env-0-src env-std env-ucache || return

# XXX: remove from env; TODO: disable undefined check during init.sh,
# or when dealing with other dynamic env..

sh_include env-0-1-lib-sys ||
  return

sh_include env-0-5-lib-log env-0-6-lib-git ||
  return

sh_include exec || return

: "${TMPDIR:=/tmp}"
: "${RAM_TMPDIR:=}"
