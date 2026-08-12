# Copyright 2026 hari <dev@dotmpe>
#
# Distributed under terms of the MIT license.
#shellcheck disable=2128

userscripts::string::case_insensitive_glob ()
{
: param '~ <Glob-var> [<Glob-pattern-value>]'
: about 'Build glob for given glob that is completely case-insensitive'
: extended 'This is only for ASCII, unicode support would be more involved'
: input "${1:?$FUNCNAME${*:+ $*}: Glob variable}"
  local -n _us_str_glob1=${1}
  [[ ${2:+set} ]] && _us_str_in1=${2} || _us_str_in1=${_us_str_glob1}
  _us_str_glob1=
  while read -r -n 1 _us_str_char1
  do
    case "$_us_str_char1" in
    ( [A-Za-z] ) _us_str_glob1+="[${_us_str_char1^}${_us_str_char1,}]" ;;
    ( * ) _us_str_glob1+="${_us_str_char1}"
    esac
  done <<< "$_us_str_in1"
}

userscripts::string::globmatch ()
{
: about "Inline glob match of String to Pattern"
: param " ~ <Pattern> <String> ..."
: id str/globmatch
: input "${1:?$FUNCNAME${*:+ $*}: Pattern}"
: input "${2:?$FUNCNAME${*:+ $*}: String value}"
#shellcheck disable=2254 # variable glob pattern is intentional
  case "${2}" in ( ${1} ) ;; * ) false ;; esac
}

userscripts::string::globreverse ()
{
: about 'Bash quick reverse of concatenated strings'
: param ' ~ <Split-match> <Var-name> ...'
  : XXX 'Splits can be character ranges, but then those should reverse properly'
: id str/globreverse
: input "${1:?$FUNCNAME: Split match}"
: input "${2:?$FUNCNAME:$1: Variable name}"
  local -n __globreverse_ref="${2}"
  userscripts::string::globreverse_from "${1}" "${__globreverse_ref}" "${2}"
}

userscripts::string::globreverse_from ()
{
: about 'Bash quick reverse of concatenated strings'
: param ' ~ <Split-match> <From-value> <To-var> ...'
: input "${1:?$FUNCNAME: Split match}"
: input "${2:?$FUNCNAME:$1: Variable name}"
  local __globreverse_tmp=${2:?$FUNCNAME:$1: Value to reverse}
  local -n __globreverse_to="${3:?}"
  local __globreverse_val
#shellcheck disable=2295 # variable patterns are intentional
  while userscripts::string::globmatch "*${1}*" "$__globreverse_tmp"
  do
    : "${__globreverse_tmp##*${1}}"
    __globreverse_val=${__globreverse_val:+${__globreverse_val}${1}}${_}
    __globreverse_tmp="${__globreverse_tmp%${1}*}"
  done
  [[ -z "${__globreverse_tmp-}" ]] || {
    __globreverse_val=${__globreverse_val:+${__globreverse_val}${1}}${__globreverse_tmp}
  }
  __globreverse_to=$__globreverse_val
}

userscripts::string::globreverse_replace ()
{
: about 'Reverse at and replace separator'
: param ' ~ <Split-match> <New-sep> <Value> <Var-to> ...'
  local -n __globreverse_tr_to=${4}
  userscripts::string::globreverse_from "${1}" "${3}" "${4}" &&
  __globreverse_tr_to=${__globreverse_tr_to//$1/$2}
}

userscripts::string::join ()
{
: param '<Dest> <Sep> <Str...>'
: about 'Join strings with separator, and store result at destination'
: extended 'Wrapper for join_array that creates temp array from arguments'
: completion 'complete -A arrayvar'
  local -a _us_str_a1=( "${@:3}" )
  userscripts::string::join_array "${1}" _us_str_a1 "${2}"
}

userscripts::string::join_array ()
{
: param '<Dest> <Src-arr> [<Sep>] ...'
: completion 'complete -A arrayvar'
  local -n _us_str_d2=${1-}
  local -n _us_str_a2=${2-}
  local _us_str_s2
  _us_str_d2=${_us_str_a2[0]}
  for _us_str_s2 in "${_us_str_a2[@]:2}"
  do
    _us_str_d2=${_us_str_d2}${3-}${_us_str_s2}
  done
}

userscripts::core::pipe_sync ()
{
  local -a command
  while (($#))
  do command+=( "$1" ); shift
    [[ $1 == -- ]] || continue
    shift; break
  done
  if_ok "$("${command[@]}")" &&
  "${@}" <<< "$_"
}

userscripts::string::lines_prefix ()
{
: input "${1:?$FUNCNAME: Prefix string}"
  userscripts::string::lines_surround "$1" "" "${@:2}"
}

userscripts::string::lines_slice ()
{
: param '~ <Start> <Len> ...'
: about 'Slice lines'
  local start=${1:-0} len=${2}
  while read -r line
  do
    [[ ${len:+set} ]] &&
      echo "${line: $start:$len}" ||
      echo "${line: $start}"
  done
}

userscripts::string::lines_suffix ()
{
: input "${1:?$FUNCNAME: Suffix string}"
  userscripts::string::lines_surround "" "$1" "${@:2}"
}

userscripts::string::lines_surround ()
{
: param '~ Prefix Suffix [Dest] [Input]'
  local _us_str_ls_in __us_str_dest
  local -n _us_str_ls_dest=${3:-__us_str_dest}
  # XXX: use dest as optional source perhaps
  if [[ ${4:+set} && $4 != - ]]; then
    _us_str_ls_in=$4
  else
    read -rd '' _us_str_ls_in
  fi
  : "${_us_str_ls_in}"
  : "${1}${_//$'\n'/$'\n'${1}}"
  : "${_//$'\n'/${2}$'\n'}${2}"
  _us_str_ls_dest=$_
  [[ ${!_us_str_ls_dest} != __us_str_dest ]] || echo "$_us_str_ls_dest"
}

# Id: us-str         vim:set ft=bash sw=2 sts=2 et:
