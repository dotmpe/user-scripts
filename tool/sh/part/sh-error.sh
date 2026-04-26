sh_error () # ~
{
  local status=$?
  local -n _STATUS=${1}
  test "${status:?}" "${@:2}" && return
  _STATUS=$status
  return ${_STATUS:?}
}
# Copy: INC:
