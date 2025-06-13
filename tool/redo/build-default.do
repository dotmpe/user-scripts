#!/usr/bin/env bash

# Created: 2025-06-09

[[ ${BASH+set} ]] ||
  _CRIT "-us-build-default.do is incompatible with shell ${SHELL:-(unspecified)}" ||
  exit

fnmatch "* uc-env-core *" " ${ENV_BASE-} " ||
  _CRIT "-us-build-default.do requires uc-env-core, base: ${ENV_BASE:-(unspecified)}" ||
  exit

# Set session and restart uc-env
sh_mode strict
uc_env +continue

[[ ${uc_env_parts[*]+set} ]] &&
[[ ${uc_env_type["uc_fun"]+set} ]] &&
[[ ${uc_env_parts["us-system.G"]+set} ]] ||
  _CRIT "-us-build-default.do missing uc-env parts, base: ${ENV_BASE:-(unspecified)}" ||
  exit

# Setup uc-env for REDO
uc_env @part G redo
uc_env @exports \
  REDO{,_{BASE,CHEATFDS,COLOR,CYCLES,DEPTH,LOG{,_INODE},NO_OOB,PRETTY,PWD,RUNID,STARTID,TARGET,UNLOCKED}

uc_env @part G default-do
default_do_main ()
{
  BUILD_TARGET=${1:?}
  BUILD_TARGET_BASE=$2
  BUILD_TARGET_TMP=$3

  declare ERROR STATUS BUILD_SELECT_SH

  # Try local project default target-mapping
  [[ ! -e "${BUILD_SELECT_SH:=./.build-select.sh}" ]] &&
  unset BUILD_SELECT_SH || {
    . "${BUILD_SELECT_SH:?}" && STATUS=0 ||
    test "${_E_next:-196}" -eq $? || return $_
  }

  # Use static project default target-mapping
  [[ 0 -eq ${STATUS:-1} ]] || case "${1:?}" in

    * ) >&2 echo "? $1"
        false
      ;;

  esac

  # End build if handler has not exit already
  exit $?
}

[[ ! ${REDO_RUNID+set} ]] ||
  default_do_main "$@"
