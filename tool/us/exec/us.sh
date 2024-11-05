#!/usr/bin/env bash

us-env -r user-script || ${us_stat:-exit} $?

us_sh_name="User Script Main"
us_sh_version=0.0.1-dev
us_sh_defcmd=status
us_sh_maincmds=help,status
us_sh_shortdescr=

us_sh__grp=user-script


! script_isrunning "us" .sh || {
  script_base=us-sh
  user_script_load || ${us_stat:-exit} $?
  user_script_defarg=defarg\ aliasargv
  if_ok "$(user_script_defarg "$@")" &&
  eval "set -- $_" &&
  script_run "$@"
}
