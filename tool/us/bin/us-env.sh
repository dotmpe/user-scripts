#!/usr/bin/env bash


## Bootstrap

# XXX cannot export arrays
#[[ ${us_node[*]+set} ]] ||
#  $LOG warn "" "Broken env, repair us-env group or check shell profile"

# us-env obviously cannot recurse on itself to do bootstrap, so it hard codes a
# sequence of env parts to load for bootstrapping instead.
#us-env -r user-script || ${us_stat:-exit} $?


us_env__grp=us
us_env__libs=us,lib-uc,str-uc
us_env_sh__grp=us-env,user-script,user-script-sh

us_env_name="User Script Environment"
us_env_version=0.0.1-dev
us_env_defcmd=short
us_env_maincmds=help
us_env_shortdescr=


us_env_fun ()
{
  local -n names
  if_ok "$(us_env_funsets)" &&
  for names in $_
  do
    : "${names//,/ }" &&
    test -n "$_" &&
    echo $_ ||
    stderr echo "us-env: No funs in set '${!names}'"
  done
}

us_env_funsets ()
{
  : "${us_env_funsets//[:.-]/_}"
  : "${_//[ ,]/$'\n'}"
  <<< "$_" str_suffix _fun
}

us_env_generate ()
{
  us_env_source ||
    $LOG error "" "Problem sourcing env part" E$? $? || return
  us_env_generate_funs &&
  echo "us_env_loadenv || test \${_E_continue:-${_E_continue:-195}} -eq \$?"
}

us_env_generate_funs ()
{
  set -- $(us_env_fun) &&
  [[ $# -gt 0 ]] ||
    $LOG error "" "No functions" "" 1 || return
  stderr echo "us-env: Generating from $# funs" &&
  local -A funexp &&
  local fun &&
  for fun
  do
    [[ ${funexp["$fun"]+set} ]] && continue
    declare -f $fun &&
    echo "declare -fx $fun" &&
    funexp["$fun"]= ||
    $LOG error "" "Exporting '$fun'" E$? $? || return
  done
}

us_env_source ()
{
  local name vid
  : "${us_env_funsets:?}"
  set -- ${_//[ ,]/$'\n'}
  for name
  do
    vid="${name//[^A-Za-z0-9_]/_}"
    : "${vid}_fun"
    [[ ${!_-} ]] && continue
    : "${us_env_srcname["$name"]:-$name}" &&
    us_env_src__"${us_env_srctype["$_"]:-lib}" "$_" ||
      $LOG error "" "Loading env part" "E$?:$name" $? || return
  done
}

us_env_src__lib ()
{
  : "${1:?}" &&
  lib_uc_require "${_%.lib}" &&
  lib_uc_init "$_"
}

us_env_src__scr ()
{
  uc_script_load "${1:?}"
}


us-env ()
{
  : source "us-env.sh"
  [[ ${us_node[*]+set} ]] || us_env_loadenv ||
    test ${_E_continue:-195} -eq $? ||
    $LOG error ":us-env" "Illegal status" "E$_" $_ || return
  local args
  case "${*:?}" in
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
  ( -q | --query )
      [[ ${us_node["$2"]-} ]]
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
   * ) $LOG error :us-env "No such action" "$1" ${_E_nsa:-68}
  esac
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

  #sys_varfcase2 us_node A ||
  [[ ${us_node[*]+set} ]] || {
    declare -gxA us_node
    us_node[us]=
    us_node[us-env]=
  }
  [[ ${us_node_base[*]+set} ]] || {
    declare -gxA us_node_base=(
      [sys-debug]=sys
      [us-env]=us
    )
  }
  #declare -gA us_env_type=(
  #  [sys]=lib
  #)
  declare -xgA us_env_srctype=(
    #[str-uc]=lib
    #[sys]=lib
    #[us]=lib
  )
  declare -xgA us_env_srcname=(
    [sys-debug]=sys
  )
  us_env_funsets=lib-uc,str-uc,sys-debug,us-env,uc-env,us

  us_env_funspec="us_env_{fun{,sets},generate{,_funs},loadenv,source}"
  us_env_fun=$(eval "echo ${us_env_funspec:?}")

  uc_env_fun=add_path,str_word,str_append,sys_nconcatl,sys_nconcatn,uc_fun,uc_debug

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
