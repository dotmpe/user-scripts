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
  declare -gA us_env_srctype=(
    #[str-uc]=lib
    #[sys]=lib
    #[us]=lib
  )
  declare -gA us_env_srcname=(
    [sys-debug]=sys
  )
  us_env_funsets=lib-uc,str-uc,sys-debug,us-env,uc-env,us

  us_env_funspec="us_env_{fun{,sets},generate{,_funs},loadenv,source}"
  us_env_fun=$(eval "echo ${us_env_funspec:?}")
  uc_env_fun=str_word,str_append,sys_is_arr,sys_nconcatl,sys_nconcatn,uc_fun,uc_debug,std_not,if_ok
}

us_env_node_init ()
{
  cache_loadmaps index,env,node,us.sh \
    us_env_basemap
}

us_argv_rev ()
{
  : copy argv.lib.sh
  : param ' ~ <Arguments...> <Dest>'
  : note "See also sys-rarr* to reverse copy between arrays"
  [[ $# -ge 2 ]] || return ${_E_MA:-194}
  local -n _argv_rev_to=${@: -1}
  local _i
  for ((_i=$#-1;_i>0;_i--))
  do
    _argv_rev_to+=( "${@:_i:1}" )
  done
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
  us_env_typeset &&
  echo "us_env_loadenv || test \${_E_continue:-${_E_continue:-195}} -eq \$?"
}

us_env_node_baselist ()
{
  local sp=tool/${1:-sh}/part
  local -n _bd _us_env_node_baselist=${2:-us_env_node_bases}
  for _bd in C_INC UCONF U_C U_S HTDOC PWD
  do
    [[ -d "$_bd/$sp" ]] || continue
   _us_env_node_baselist+=( "$_bd/$sp" )
  done
}

us_env_node_list ()
{
  local pd scr_{path,leaf,name,base}
  local -a us_env_node_bases
  us_env_node_baselist "" us_env_node_bases &&
  us_env_node_baselist "bash" us_env_node_bases &&
  for pd in "${us_env_node_bases[@]}"
  do
    for scr_path in $pd/*.{,ba}sh
    do
      scr_leaf=${scr_path: ${#pd}+1}
      : "${scr_leaf%.sh}"
      scr_name=${_%.bash}
      case "$scr_name" in *,* )
        us_env_namepath "$scr_leaf"

        ;; * )
        # >&2 declare -p scr_{path,name,base}
      esac
    done
  done
}

us_env_namepath ()
{
  # Create byname maps at each base,
  # then check if uname is unique within base
  : input "${1:?Leaf name}"
  local env_{uname,base} _basepath=
  : "${1%.bash}"
  env_uname=${_%.sh}
  #local -n _base_ref=us_node_base[\"\$env_base\"]
  local -a bases
  us_argv_rev ${env_uname//,/ } bases &&
  unset "bases[-1]" &&
  >&2 declare -p env_uname &&
  for env_base in "${bases[@]}"
  do
    #os_lookup_add ${env_base} _base_ref &&
    os_lookup_add ${env_base} _basepath &&
    >&2 declare -p _basepath &&
    true
  done
  #_us_env_node_list["$1"]=$inc
}

us_env_typeset ()
{
  local -a funs
  if_ok "$(us_env_fun)" &&
  <<< "${us_env_fun}" mapfile -t funs &&
  [[ ${#funs[@]} -gt 0 ]] ||
    $LOG error "" "No functions" "" 1 || return
  stderr echo "us-env: Generating from $# funs"
  local -A funexp &&
  local fun &&
  for fun in "${funs[@]}"
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

# profile = bash
#us-env.fun ()
#{
#  local -n names
#  if-ok "$(us-env.funsets)" &&
#  for names in $_
#  do
#    : "${names//,/ }" &&
#    test -n "$_" &&
#    echo $_ ||
#    stderr echo "us-env: No funs in set '${!names}'"
#  done
#}
