assert_lib__load ()
{
  lib_require os &&
  declare -gA ASSERT=(
    [isblock]=os
    [ischar]=os
    [isdir]=os
    [isfile]=os
    [islink]=os
    [isnonempty]=os
    [ispath]=os
    [issymlink]=os
    [private]=os

    #[isdigit]=sys/test
    #[isfloat]=sys/test
    #[isisnum]=sys/test
    #[inrange]=sys/test

    [globmatch]=str
    [rematch]=str
  )
}


assert () # ~ <Test args...> [ -- <Argv> ]
{
  ! sys_debug assert || {

    assert_${1:?} "${@:2}"
    return
  }

  "${ASSERT["${1:?}"]:-test}_${1:?}" "${@:2}"
}

# XXX: helper for verbose arguments-count-check, but doesnt provide feedback
# on actual received arguments by itself
assert_argc () # ~ <Expected> <Actual> ...
{
  declare lk=${lk:-}:assert-argc
  : "${1:?$lk: Expected argument count expected}"
  : "${2:?$lk: Actual argument count expected}"
  [[ $2 -eq $1 ]] || {
    [[ $2 -eq 0 ]] && {
      $LOG warn "$lk" "No arguments, expected $1" "" ${_E_MA:?}
      return
    } ||
      [[ $2 -lt 0 ]] && {
        $LOG warn "$lk" "Missing arguments" "$2/$1" ${_E_GAE:?}
        return
      } ||
        $LOG warn "$lk" "Surpluss arguments" "$2>$1" ${_E_GAE:?}
  }
}


## Local (file system) assertions

assert_isblock () # ~ <Name>
{
  declare lk=${lk:-}:assert-isblock
  : "${1:?$lk: Path name expected}"
  os_isblock "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_ischar () # ~ <Name>
{
  declare lk=${lk:-}:assert-ischar
  : "${1:?$lk: Path name expected}"
  os_ischar "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_isdir () # ~ <Name>
{
  declare lk=${lk:-}:assert-isdir
  : "${1:?$lk: Path name expected}"
  os_isdir "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_isfile () # ~ <Name>
{
  declare lk=${lk:-}:assert-isfile
  : "${1:?$lk: Path name expected}"
  os_isfile "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_islink () # ~ <Name>
{
  declare lk=${lk:-}:assert-islink
  : "${1:?$lk: Path name expected}"
  os_islink "$_" ||
    $LOG warn "$lk" "No such link" "E$?:name=$1" ${_E_fail:?}
}

assert_isnonempty () # ~ <Name>
{
  declare lk=${lk:-}:assert-isnonempty
  : "${1:?$lk: Path name expected}"
  os_isnonempty "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_ispath () # ~ <Name>
{
  declare lk=${lk:-}:assert-ispath
  : "${1:?$lk: Path name expected}"
  os_ispath "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}
# alias: test-exists

assert_issymlink () # ~ <Name>
{
  declare lk=${lk:-}:assert-issymlink
  : "${1:?$lk: Path name expected}"
  os_issymlink "$_" ||
    $LOG warn "$lk" "No such symlink" "E$?:name=$1" ${_E_fail:?}
}

assert_private () # ~ <File>
{
  declare lk=${lk:-}:assert-private
  assert_isfile "${1:?}" && {

    local assert_mode
    : "${1:?$lk: Path name expected}"
    os_private "$_" assert_mode ||
      $LOG warn "$lk" "File access too open" "E$?:name=$1:$assert_mode" ${_E_fail:?}
  }
}

## Numeric assertions

assert_isdigit () # ~ <String>
{
  [[ "$1" =~ ^[0-9]$ ]] ||
    $LOG warn "$lk" "Not a digit" "E$?:string=$1" ${_E_fail:?}
}

assert_isfloat () # ~ <String>
{
  [[ "$1" =~ ^[+-]?[0-9]+\.[0-9]+$ ]] ||
    $LOG warn "$lk" "Not a float" "E$?:string=$1" ${_E_fail:?}
}

assert_isnum () # ~ <String>
{
  [[ "$1" =~ ^[+-]?[0-9]+$ ]] ||
    $LOG warn "$lk" "Not a number" "E$?:string=$1" ${_E_fail:?}
}

assert_inrange () # ~ <Int> [<255> [<0>]]
{
  [[ ${3:-0} -le "$1" && $1 -le ${2:-255} ]] ||
    $LOG warn "$lk" "Out of range" "E$?:$*" ${_E_fail:?}
}
# alias assert-bytenum


## String assertions - indices

## String assertions - glob matches

assert_globmatch () # ~ <String> <Glob>
{
  declare lk=${lk:-}:assert-globmatch
  #str_globmatch "$1" "$2"
  fnmatch "$2" "$1" ||
    throw "$lk" "${3-Expression failed}" "$1:$2" || return
}

## String assertions - regular expressions

assert_rematch () # ~ <String> <Expr>
{
  declare lk=${lk:-}:assert-rematch
  [[ "$1" =~ $2 ]] ||
    throw "$lk" "${3-Expression failed}" "$1:$2" || return
}

#
