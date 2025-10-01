#!/usr/bin/env bash

# companion specs for us-env exec

us-env:meta ()
{
  : group us
  : base user-script
  #: deps
  #: libs
  #: type script-exec
}

us-env:define-env ()
{
  #sys_varfcase2 us_node A ||
  [[ ${us_node[*]+set} ]] || {
    declare -gA us_node
    us_node[us]=
    us_node[us-env]=
  }
  [[ ${us_node_base[*]+set} ]] || {
    declare -gA us_node_base=(
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

  uc_env_fun=str_word,str_append,sys_is_arr,sys_nconcatl,sys_nconcatn,uc_fun,uc_debug,std_not,if_ok
}

#us-env:fun ()
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
    $LOG debug "" "Sourcing env part" "$name"
    : "${us_env_srcname["$name"]:-$name}" &&
    us_env_src__"${us_env_srctype["$_"]:-lib}" "$_" ||
      $LOG error "" "Loading env part" "E$?:$name" $? || return
  done
}

us_env_src__lib ()
{
  : "${1:?}"
  : "${_%.lib}"
  lib_uc_require "${_:?}" &&
  lib_uc_init "$_"
}

us_env_src__scr ()
{
  uc_script_load "${1:?}"
}


us-env.fun ()
{
  local -n names
  if-ok "$(us-env.funsets)" &&
  for names in $_
  do
    : "${names//,/ }" &&
    test -n "$_" &&
    echo $_ ||
    stderr echo "us-env: No funs in set '${!names}'"
  done
}
