
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
