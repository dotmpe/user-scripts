env:bash-fun:meta ()
{
  us: group us
  us: shtype group
}


sh-fclone () # ~ <New-name> <Copy-ref> # alias:fun-clone
{
  : "${1:?$FUNCNAME: New function name expected}"
  : "${2:?$FUNCNAME: Reference function name expected}"
  if-ok "${1} () {
$(sh-funbody "${2}")
}" &&
  eval "${_}"
}

sh-fun () # ~ <Fun>
{
  : "${1:?$FUNCNAME: Function name expected}"
  std-quiet declare -F "${1}"
}

sh-funbody () # ~ <Name>
{
  : "${1:?$FUNCNAME: Function name expected}"
  if-ok "$(std-quiet declare -f "${1}")" || return
  : "${_#* () }"
  : "${_:4:-2}"
  echo "${_}"
}

sh-fundef () # ~ <Name> <Fun-body>
{
  : "${1:?$FUNCNAME: Function name expected}"
  : "${2:?$FUNCNAME: ${1}: Function body expected}"
  : "${1} () { ${2}$'\n' }"
  eval "$_"
}

std-quiet () # ~ <Cmd...> # Silence all output (std{out,err})
{
  "$@" >/dev/null 2>&1
}

#
