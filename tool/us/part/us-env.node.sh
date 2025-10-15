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
  cache_loadmaps \
    index,env,node,us.sh \
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
  us_env_funset &&
  echo "us_env_loadenv || test \${_E_continue:-${_E_continue:-195}} -eq \$?"
}

us_env_node_baselist ()
{
  : about ' ~ <Suite> <Array> [<Env-vars>]'
  : about "Load every existing tool/$1/part basedir into array"
  local sp=tool/${1:-sh}/part
  local -n _bd _us_env_node_baselist=${2:-us_env_node_bases}
  ! (($#-2)) &&
    local -a _us_env_node_bases=( C_INC UCONF U_C U_S HTDOC PWD ) ||
    local -n _us_env_node_bases=${3:?Basedir array expected}
  for _bd in "${_us_env_node_bases[@]}"
  do
    [[ -d "$_bd/$sp" ]] || continue
   _us_env_node_baselist+=( "$_bd/$sp" )
  done
}

us_env_node_list ()
{
  : param ' ~ [<Suites...>]'
  (($#)) || set -- ba{,sh}
  local suite pd scr_{path,leaf,name,base}
  local -a us_env_node_bases
  for suite
  do us_env_node_baselist "$suite" us_env_node_bases || return
  done &&
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

us_env_funset ()
{
  : param ' ~ <Funsets> '
  : about 'Typeset functions, listing full definition and export declaration is applicable'
  local -n funset_str=${1//-/_}_funsets
  local -a funsets=( ${funsets_str//,/ } )
  local -A funs
  us_env_funsets_load funs "${funsets[@]}" &&
  [[ ${#funs[@]} -gt 0 ]] ||
    $LOG error "" "No functions" "" 1 || return

  local fun
  stderr echo "us-env: Generating from ${#funs[@]} funs"
  for fun in "${!funs[@]}"
  do
    declare -f $fun &&
    echo "declare -fx $fun"
  done
}

us_env_funsets_load ()
{
  : param ' ~ <Id-var> <Name-var> ...'
  TODO "$FUNCNAME: $*"
}

us_env_cname () # ~ <Name-ref> <Base-ref> <To-var>
{
  local nameref=${1:?} baseref=${2:?}
  local -n _cname=${3:?}
  case "${nameref}" in
  ( -* ) _cname=${baseref%:*}:${nameref:1}
    ;;
  ( .* ) _cname=${baseref}:${nameref:1}
    ;;
  ( * ) _cname=${nameref}
  esac
}

us_env_idtoname ()
{
  : param ' ~ <Id-var> <Name-var> ...'
  local -n __idtoname_id=${1:?Id var}
  : input "${2:?Name var}"
  globreverse_tr ',' '-' "$__idtoname_id" "${2}"
}

us_env_nametoid ()
{
  : param ' ~ <Name-var> <Id-var> ...'
  local -n __nametoid_name=${1:?Name var}
  : input "${2:?Id var}"
  globreverse_tr '-' ',' "$__nametoid_name" "${2}"
}

us_env_partattr ()
{
  : about 'Load meta fields into map'
  : param ' ~ <Part> <Array> <Fields...>'
  : extended 'This works for fields with single (long) string values'
  TODO "uses uc-cmp :metafor, see uc-env."
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

us_env_typeset_sh ()
{
  : param ' ~ <Group> <Deps> ...'
  local groupname=${1?} groupid
  us_env_nametoid group{name,id}

  . "${groupid}.inc" &&
  local _typeset
  local _{id,group,type} \
        _{parts,import,export,dynfun,nameals}

  _typeset="$(declare -f ${groupname//-/:})" || return

  us_env_inc_key_value _typeset _ {id,group,type}
  us_env_inc_key_all_values _typeset _ {import,export}

  : "${_id:=$groupname}"
  : "${_type:=group}"
  : "${_group:=${groupname%-*}}"
  [[ ${_group} != "${groupname}" ]] || _group=
  [[ ${_export[@]:+set} ]] || _export=( 'parts' )

  # Now run all parts and sort out which command name aliases can be exported,
  # and serialize group and parts. Then recurse for all imports as well.

  for k in ${_export[@]}
  do
    local -n _k=_${k//-/_}
    us_env_inc_key_all_value_seqs _typeset _ $k &&
    us_env_typeset_${k//-/_}_sh __out _parts \
      "${_k[@]:? _k array exp for $k at $groupname}"
  done

  __out="${__out:-}${groupname//-/_} () {
  : id ${_id}
  : type ${_type}
  : group ${_group}
  : parts ${_parts[@]}
}
"

  [[ ! ${_import[@]:+set} ]] || {
    for name in "${_import[@]}"
    do
      fullname="${groupname}-${name#\/}"
      us_env_nametoid full{name,id}
      incpath="$(command -v "${fullid}.inc")" &&
      filepath=${incpath%.inc}.sh &&
      toolpath=tool${filepath#*/[Tt]ool} &&
      _deps+=( "${toolpath}" ) &&
      __out=${__out}.\ \"${filepath}\"$'\n' ||
      >&2 echo "Cannot locate $fullid.inc"
    done
    >&2 declare -p _import
  }

  echo "$__out"
}

us_env_inc_key_value ()
{
  local -n _ueikv_typeset=${1:?}
  local pref=${2?} key
  for key in "${@:3}"
  do
    <<< "$_ueikv_typeset" uc_cmp :metafor+one ${pref}${key//-/_} ${key}
  done
}

us_env_inc_key_values ()
{
  local -n _ueikv_typeset=${1:?}
  local pref=${2?} key
  for key in "${@:3}"
  do
    <<< "$_ueikv_typeset" uc_cmp :read-field+aliased ${pref}${key//-/_} ${key}
  done
}

us_env_inc_key_all_values ()
{
  local -n _ueikav_typeset=${1:?}
  local pref=${2?} key
  for key in "${@:3}"
  do
    <<< "$_ueikav_typeset" uc_cmp :read-field+aliased+all ${pref}${key//-/_} ${key}
  done
}

us_env_inc_key_all_value_seqs ()
{
  local -n _ueikav_typeset=${1:?}
  local pref=${2?} key
  for key in "${@:3}"
  do
    <<< "$_ueikav_typeset" uc_cmp :read-field+aliased+seqs ${pref}${key//-/_} ${key}
  done
}

us_env_typeset_nameals_sh ()
{
  local -n __dest=${1:?} __parts=${2:?}
  shift 2
  local argc=0 idx
  while (($#))
  do
    [[ $argc -lt $# && ${!argc} != '--' ]] && {
      ((argc+=1))
      continue
    }
    [[ ${!argc} == '--' ]] && idx=$argc-1 || idx=$argc
    __dest=${__dest:+$__dest }"name_alias$(printf ' "%s"' "${@:1:$idx}")"$'\n'
    __parts+=( "${@:2:$idx-1}" )
    shift $argc
  done
}

us_env_typeset_dynfun_sh ()
{
  local -n __dest=${1:?} __parts=${2:?}
  shift 2
  while (($#))
  do
    __dest=${__dest:+$__dest }"${1:?} () { ${2:?}; }"$'\n'
    __parts+=( "$1" )
    shift 3
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

# XXX: revisit classses later, profile = bash
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
