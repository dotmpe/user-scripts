# Copyright 2026 hari <dev@dotmpe>
#
# Distributed under terms of the MIT license.

userscripts::use ()
{
  local _prefix=$1:: _as=${2-}
  local _fullname _localname _privpref _import _funbody
  local -a functions
  compgen -A function -X "!$1::*" -V functions &&
  for _fullname in "${functions[@]}"
  do
    _localname=${_fullname#"$_prefix"}
    userscripts::shell::function_body $_fullname _funbody
    userscripts::shell::metafor alias _import <<< "$_funbody" || {
      userscripts::shell::metafor private-prefix _privpref <<< "$_funbody" &&
      _import=${_privpref}${_localname} ||
        _import=${_localname}
    }
    if [[ ${as-} ]]
    then
      TODO "may be actually rewrite body?"
    else
      ! ((DEBUG)) ||
      >&2 echo "mapping $_import to $_fullname"
      . <(echo "$_import () { $_fullname \"\$@\"; }")
    fi
  done
}

# Id: us-use                                    vim:set ft=bash sw=2 sts=2 et:
