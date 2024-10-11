
us_lib__load ()
{
  us_fun=fnmatch,incr,lib_init,lib_load,lib_require,os_path_add,std_noout,std_quiet,std_silent,stderr,str_globmatch,sys_default,sys_astat,sys_loop,sys_nconcatl,us_debug,us-env
}

us_lib__init ()
{
  #test -z "${ansi_uc_lib_init-}" || return $_
  lib_require sys str || return
  ! { "${DEBUG:-false}" || "${DEV:-false}" || "${INIT:-false}"; } ||
  ${LOG:?} info ":us:lib-load" "Initialized us.lib"
}

us_env_init ()
{
  : source "us.lib.sh"
  declare -xgA us_node=() us_src=() &&
  #export us_node &&
  export -f us-env \
    sys_nconcat{n,l} \
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
