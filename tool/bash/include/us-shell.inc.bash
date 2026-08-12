# Copyright 2026 hari <dev@dotmpe>
#
# Distributed under terms of the MIT license.
#shellcheck disable=2128

userscripts::shell::function_declare ()
{
: param '<Function-name> <Function-body>'
: input "${1:?$FUNCNAME${*:+ $*}: Function name, $ENV_CTX}"
: input "${2:?$FUNCNAME${*:+ $*}: Function body, $ENV_CTX}"
: "${1} () { ${*:2}; }"
  . <(echo "$_")
}

userscripts::shell::function_body ()
{
: param '<Ref-fun> [<Dest>] ...'
: aliases sh-fbody fun-body
  local _str
  local -n _dest=${2:-_str}
: input "${1:?$FUNCNAME: Function name expected}"
  if_ok "$(typeset -f "$_")" || return
  : "${_#* () }"
  : "${_:4:-2}"
  _dest="$_"
  [[ ${!_dest} != _str ]] || echo "$_dest"
}

#userscripts::shell::function::metafor ()
userscripts::shell::metafor ()
{
  local -n _dest=${2}
  if_ok "$(grep -Po '^[ \t]*: '"$1"' \K.*$')" &&
  _dest=${_%;}
}

# Id: us-shell                                   vim:set ft=bash sw=2 sts=2 et:
