assert_lib__load ()
{
  lib_require os
}


assert_isblock () # ~ <Name>
{
  typeset lk=${lk:-}:assert-isblock
  : "${1:?$lk: Path name expected}"
  test_isblock "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_ischar () # ~ <Name>
{
  typeset lk=${lk:-}:assert-ischar
  : "${1:?$lk: Path name expected}"
  test_ischar "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_isdir () # ~ <Name>
{
  typeset lk=${lk:-}:assert-isdir
  : "${1:?$lk: Path name expected}"
  test_isdir "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_isfile () # ~ <Name>
{
  typeset lk=${lk:-}:assert-isfile
  : "${1:?$lk: Path name expected}"
  test_isfile "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_isnonempty () # ~ <Name>
{
  typeset lk=${lk:-}:assert-isnonempty
  : "${1:?$lk: Path name expected}"
  test_isnonempty "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

assert_ispath () # ~ <Name>
{
  typeset lk=${lk:-}:assert-ispath
  : "${1:?$lk: Path name expected}"
  test_ispath "$_" ||
    $LOG warn "$lk" "No such path" "E$?:name=$1" ${_E_fail:?}
}

#
