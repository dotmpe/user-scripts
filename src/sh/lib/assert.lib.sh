assert_lib__load ()
{
  lib_require os
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

#
