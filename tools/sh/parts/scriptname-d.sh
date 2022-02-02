#!/usr/bin/env bash

push_scriptname ()
{
  test -z "${scriptname-}" ||
    SCRIPTNAME_D="${SCRIPTNAME_D:-}${SCRIPTNAME_D:+" "}$scriptname"
  export scriptname="$1"
}

pop_scriptname ()
{
  export scriptname="${SCRIPTNAME_D//* }"
  SCRIPTNAME_D="${SCRIPTNAME_D% *}"
}

scriptname_include ()
{
  local stat scriptname
  for scriptname in $@
  do
    push_scriptname $scriptname
    sh_include $scriptname || stat=$?
    pop_scriptname
  done
  return ${stat-}
}

# Id: U-S:
