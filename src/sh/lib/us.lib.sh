us_lib__load ()
{
  us_fun=fnmatch,func_exists,incr,lib_init,lib_load,lib_require,append_path,lookup_path,std_noo,std_not,std_quiet,std_silent,stderr,str_globmatch,sys_rarr,sys_rarr2,sys_default,sys_astat,sys_loop,sys_nconcat1r,us_debug,us-env
  lib_init () { lib_uc_init "$@"; }
  lib_load () { lib_uc_load "$@"; }
  lib_require () { lib_uc_require "$@"; }
  #us_part --alias us-os us-std
}

us_lib__init ()
{
  #test -z "${ansi_uc_lib_init-}" || return $_
  lib_require sys str || return
  ! ((DEBUG)) || {
    ! ((INIT)) && ! ((DEV))
  } ||
    ${LOG:?} info ":us:lib-load" "Initialized us.lib"
}

us_lib_man_1__env_init='us-lib:env-init user shell profile helper to get
shell libraries and some basic variables and function set for user-scripts. XXX: old, ie etc/profile.d/. '
us_lib__env_init ()
{
: source "us.lib.sh"
  declare -xgA us_node=() us_src=() &&
  #export us_node &&
  export -f us-env \
    sys_nconcat{n,1r} \
    sys_exc &&
  export \
    _E_nsk=67 _E_nsa=68 \
    _E_not_found=124 _E_not_exec=126 _E_not_found=127 \
    _E_GAE=193 _E_MA=194 _E_continue=195 _E_next=196 _E_break=197 \
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
