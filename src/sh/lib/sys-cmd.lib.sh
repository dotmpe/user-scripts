sys_cmd_lib__load ()
{
  : about "Helpers to run commands"
  lib_require args
}

sys_cmd_lib__load ()
{
  lib_require sys
}


# Reduce arguments at offset to a single string (collapse IFS), and then invoke
# command with that. Using '$*' can be usefull from a user perspective, (as
# during processing globstars or braces it may expand a single string expression
# into multiple string values). However it makes the functions signature less
# specific (and it always collapses IFS for the values). To call such function
# the user needs to expand arguments in a subshell, or use another additional
# function (such as this one) to wrap such call:
# $ funfoo "$(echo ...)"
# $ sys_cmd_apop 1 funfoo ...
# Where '...' can be any string expression (with variables, globs or braces).
# The offset (which is ofcourse 0-index based, and which) must be >0 since a
# command name can never contain spaces.
sys_cmd_apop () # ~ <Offset> <Cmd> [ <Arguments...> ]
{
  local o=${1:?"$(sys_exc sys.lib:cmd-apop~offset "Offset expected")"}
  [[ $o -ge 1 ]] || return 2
  "${@:2:$o}" "${*:$(( o + 2 ))}"
}

# Execute commands from arguments in sequence, reading into array one segment at
# a time. Empty sequence can be used to break-off current sys-cmd-seq run, and
# pass entire rest of arguments to sys-csd. sys-csp is the prefix put before
# each command.
sys_cmd_seq () # ~ <cmd> <args...> [ -- <cmd> <args...> ]
{
  declare cmd=()
  while ${sys_csa:-args_seq_arrv} cmd "$@"
  do
    test 0 -lt "${#cmd[*]}" && shift $_ || {
      #test 0 -eq $# && return
      "${sys_cse:-false}" && cmd=( "${sys_csd:---}" ) || return
    }
    : "${sys_csp-}${sys_csp+ }${cmd[*]}"
    $LOG info "${lk-}" "Calling command" "${_//%/%%}"
    ${sys_csp-} "${cmd[@]:?}" || return
    ${sys_cis:-args_is_seq} "$@" && { shift || return; }
    test 0 -lt $# || break
    cmd=()
  done
}

sys_eval_seq () # ~ <script...> [ -- <script...> ]
{
  declare cmd=()
  while ${sys_cesa:-argv_seq} cmd "$@"
  do
    test 0 -lt "${#cmd[*]}" &&
    shift $_ &&
    : "${cmd[*]}" &&
    $LOG info "${lk-}" "Evaluating script" "${_//%/%%}" &&
    eval "${cmd[*]}" || return
    args_is_seq "$@" && shift && test 0 -lt $# ||
      break
    cmd=()
  done
}

#
