assert_lib__load ()
{
  lib_require os
}


assert () # ~ <Test args...> [ -- <Argv> ]
{
  [[ true = "${VERBOSE:-${DEBUG:-false}}" ]] && {

    assert_${1:?} "${@:2}"
    return
  } ||
    os_${1:?} "${@:2}"
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

#
