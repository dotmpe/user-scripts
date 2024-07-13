us_lib__load ()
{
  us_fun=sys_default,sys_astat,sys_loop,stderr,std_quiet,std_noout,std_silent,str_globmatch,fnmatch,incr,str_vconcat,lib_load,lib_init,lib_require,us_debug,us-env
}

us_lib__init ()
{
  lib_require sys str
}

us_env_init ()
{
  declare -gA us_node=() &&
  export us_node &&
  export -f us-env \
    str_vconcat \
    sys_exc &&
  export \
    _E_nsk=67 _E_nsa=68 \
    _E_not_found=124 _E_not_exec=126 _E_not_found=127 \
    _E_GAE=193 _E_MA=194 _E_continue=195 _E_next=196 _E_stop=197 \
    _E_done=200
}

us_debug () # ~ <Cmd>
{
  sys_debug debug || return
  "$@"
}

us-env ()
{
  local args
  args=$( getopt -o q:d:l:L:r:cu \
    --long query:,known:,load:,lookup:,require:,cycle,update -- "$@" ) &&
  eval "set -- $args" || return
  case "${1:?}" in
  ( -q | --query )
      [[ ${us_node["$2"]-} ]]
    ;;
  ( -l | --load )
      uc_script_load "$2"
    ;;
  ( -r | --require )
      [[ ${us_node["$2"]-} ]] || {
        us-env --load "$2" &&
        us_node["$2"]=
      }
    ;;
   * ) $LOG error :us-env "No such action" "$1" ${_E_nsa:-68}
  esac
}

# us-log-v-warn: if v is too low for normal interactive mode
us_log_v_warn () # ~ [<Expected-level=6>] [<Message>] [<Message-level=warn>]
{
  ${user_script_novwarn:-false} && return
  local ev=${1:-6} msg
  test $ev -eq 6 &&
      msg="${2:-Turn up verbosity to INFO for full output}" ||
      msg="${2:-Turn up verbosity for complete output}"
  # XXX: STD_INTERACTIVE
  test -t 1 || return
  test $ev -le ${verbosity:-${v:-0}} ||
      $LOG ${3:-warn} :verbosity "$msg" "1.$_:v=${v:-}"
}

# Id: U-S:us.lib
