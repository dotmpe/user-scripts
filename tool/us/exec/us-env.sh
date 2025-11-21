#!/usr/bin/env bash


## Bootstrap

# us-env obviously cannot recurse on itself to do bootstrap, so it hard codes a
# sequence of env parts to load for bootstrapping instead.
#us-env -r user-script || ${us_stat:-exit} $?


us_env__grp=us
us_env__libs=us,lib-uc,str-uc
us_env_sh__grp=us-env,user-script,user-script-sh

us_env_name="User Script Environment"
us_env_version=0.0.1-dev
us_env_defcmd=short
us_env_maincmds=help,load,query,require
us_env_shortdescr=

. "${UCONF:?}/script/composure/us-env.inc.bash"
us_env "$@"
exit

us-env-old ()
{
  [[ ${us_node[*]+set} ]] || us_env_loadenv ||
    test ${_E_continue:-195} -eq $? ||
    $LOG error ":us-env" "Illegal status" "E$_" $_ || return

  local args
  # XXX: compiled help for static function export, outer script will use
  # user-script-help functions
  case "${*:?${ENV_CTX:-$0[$$]}:us-env Arguments expected}" in
  ( -h|-?|--help )
      cat <<EOM
Command
  us-env <...>

Usage options:
  -r | --require <require-parts...>
  -E TODO
  -l | --load <load-parts...>
  -q | --query <query-parts...>

EOM
    ;;
  ( "-r us:boot.screnv" )
      local scriptenv
      # These are intended to control local script, export must be turned off first.
      for scriptenv in DEV DEBUG DIAG INIT ASSERT QUIET VERBOSE
      do
        # If set assume they are exported, un-export but keep for local session
        ! [[ ${!scriptenv+set} ]] || {
          declare -g +x ${scriptenv}=${!scriptenv?}
        }
      done
      return
    ;;
  esac &&
  args=$( getopt -o q:d:l:L:r:cu \
    --long query:,known:,load:,lookup:,require:,cycle,update -- "$@" ) &&
  eval "set -- $args" &&
  case "${1:?}" in
  ( -E | --exec )
    ;;
  ( -d | --known )
    ;;
  ( -l | --load )
      uc_script_load "$2"
    ;;
  ( -r | --require )
      #sys_vfl us_node x A ||
      #[[ ${#us_node[*]} -gt 0 ]] ||
      #[[ ${us_node[*]+set} ]] ||
      #  $LOG error "" "Broken us-env (global missing)" "a:us-node" 3 || return
      [[ ${us_node["$2"]-} ]] || {
        us-env --load "$2" &&
        us_node["$2"]=
      }
    ;;
  ( -q | --query )
      [[ ${us_node["$2"]-} ]]
    ;;
   * ) $LOG error :us-env "No such action" "$1" ${_E_nsa:-68}
  esac
}

us_env__load_parts () # ~ <Parts...>
{
  false
}

us_env__query () # ~ <Parts...>
{
  false
}

us_env_sh__require () # ~ <Parts...>
{
  false
}



## Util

if_ok ()
{
  return
}
# Copy: script-mpe.lib

str_suffix () # (s) ~ <Suffix-str> ...
{
  local str suffix=${1:?"$(sys_exc str-suffix:str@_1 "Suffix string expected")"}
  while read -r str
  do echo "${str}${suffix}"
  done
}
# Copy: str.lib

us_env_loadenv ()
{
  : source "us-env.sh"

  # XXX: do proper build and then graph init
  os_path_add "${U_S?}/tool/us/part"
  os_path_add "${U_S?}/tool/us/exec"
  {
    sh_fun us-env:define-env ||
      uc_script_load "us-env.node" || return
  } && us-env:define-env &&
  true || return
  #$LOG error : "Failed $FUNCNAME" E$? $? || return

  return ${_E_continue:-195}
}



# Static bootstrap for us-env: get env up as far as 'user-script' part, and
# load that if not already part of env.
test -n "${uc_fun_profile-}" || {
  [[ ${BASH-} ]] ||
    $LOG error "" "No implementation for shell" "$SHELL" 201 ||
    ${us_stat:-exit} $?

  : "${USER:=$(whoami)}"
  : "${HOME:=/home/${USER:?}}"
  : "${UCONF:=${HOME:?}/.conf}"

  # TODO: prepare us-env basis env set if not found or ood
  echo sourcing uc_fun.sh env part >&2
  . "${UCONF:?}/etc/profile.d/uc_fun.sh" || ${us_stat:-exit} $?
}

test -n "${uc_lib_profile-}" ||
  . "${UCONF:?}/etc/profile.d/uc_lib.sh" || ${us_stat:-exit} $?

test -n "${user_script_uc_fun_profile-}" ||
  uc_script_load user-script || ${us_stat:-exit} $?


: "${0##*\/}"
: "${_%.sh}"
case "$_" in
( us-env )
  SCRIPTNAME=us-env.sh
esac

! script_isrunning "us-env.sh" || {
  user_script_load || ${us_stat:-exit} $?
  user_script_defarg=defarg\ aliasargv
  if_ok "$(user_script_defarg "$@")" &&
  eval "set -- $_" &&
  script_run "$@"
}
