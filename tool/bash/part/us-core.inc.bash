# Copyright 2026 hari <dev@dotmpe>
#
# Distributed under terms of the MIT license.
#shellcheck disable=2128,2317

userscripts::core::_init () {
  : "${ENV_CTX:=$0[$$]}"
}

userscripts::core::echo_stderr_with_status () {
  local stat=${2:-$?}
: input "${1:?$FUNCNAME: Failure message, $ENV_CTX}"
  ((stat)) || stat=1
  >&2 echo "$1"
  return ${stat}
: alias failerr
}

userscripts::core::fnmatch () {
  [[ ${2:+set} ]] && userscripts::string::globmatch "${@}"
}

userscripts::core::globmatch () {
  [[ ${2:+set} ]] && userscripts::string::globmatch "${@}"
}

userscripts::core::ignore-status () {
  "${@:?$FUNCNAME: Command arguments, $ENV_CTX}" || true
: alias ignore
}

userscripts::core::not-status () {
  ! "${@:?$FUNCNAME: Command arguments, $ENV_CTX}"
: alias not
}

userscripts::core::pass-status () {
  return
: alias if_ok
}

userscripts::core::set-status () {
  return ${1:?$FUNCNAME: Status number, $ENV_CTX}
: alias status
}

# Id: us-core         vim:set ft=bash sw=2 sts=2 et:
