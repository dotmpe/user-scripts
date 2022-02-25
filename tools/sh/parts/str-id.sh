#!/bin/sh


# Web-like ID for simple strings, input can be any series of characters.
# Output has limited ascii.
#
# alphanumerics, periods, hyphen, underscore, colon and back-/fwd dash
# Allowed non-hyhen/alphanumeric ouput chars is customized with env 'c'
#
# mkid STR '-' '\.\\\/:_'
mkid () # ~ Str Extra-Chars Substitute-Char
{
  #test -n "$1" || error "mkid argument expected" 1
  local s="${2-}" c="${3-}"
  # Use empty c if given explicitly, else default
  test $# -gt 2 || c='\.\\\/:_'
  test -n "$s" || s=-
  test -n "${upper-}" && {
    test $upper -eq 1 && {
      id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" | tr 'a-z' 'A-Z')
    } || {
      id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" | tr 'A-Z' 'a-z')
    }
  } || {
    id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" )
  }
}
# Sync-Sh: BIN:str-htd.lib.sh

# A lower- or upper-case mkid variant with only alphanumerics and hypens.
# Produces ID's for env vars or maybe a issue tracker system.
# TODO: introduce a snake+camel case variant for Pretty-Tags or Build_Vars?
# For real pretty would want lookup for abbrev. Too complex so another function.
mksid() # STR
{
  test $# -gt 2 || set -- "${1-}" "${2-}" "_"
  mkid "$@" ; sid=$id ; unset id
}
# Sync-Sh: BIN:str-htd.lib.sh

# Variable-like ID for any series of chars, only alphanumerics and underscore
mkvid() # STR
{
  test $# -eq 1 -a -n "${1-}" || error "mkvid argument expected ($*)" 1
  test "${upper-'nil'}" = "1" && {
    vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g' | tr 'a-z' 'A-Z')
    return
  }
  test "${upper-'nil'}" = "0" && {
    vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g' | tr 'A-Z' 'a-z')
    return
  }
  vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g')
  # Linux sed 's/\([^a-z0-9_]\|\_\)/_/g'
}

# Simpler than mksid but no case-change
mkcid()
{
  cid=$(echo "$1" | sed 's/\([^A-Za-z0-9-]\|\-\)/-/g')
}

# Sync-Sh: BIN:str-htd.lib.sh
