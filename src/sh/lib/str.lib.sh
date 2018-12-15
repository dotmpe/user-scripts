#!/bin/sh


# Set env for str.lib.sh
str_lib_load()
{
  test -n "$LOG" || return 102
  test -n "$uname" || uname="$(uname -s)"
  test -n "$ext_sh_sub" || ext_sh_sub=0

  test -x "$(which php)" && bin_php=1 || bin_php=0
}

# ID for simple strings without special characters
mkid()
{
  id=$(printf -- "$1" | tr -sc 'A-Za-z0-9\/:_-' '-' )
}

# to filter strings to variable id name
mkvid()
{
  vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g')
  # Linux sed 's/\([^a-z0-9_]\|\_\)/_/g'
}
mkcid()
{
  cid=$(echo "$1" | sed 's/\([^a-z0-9-]\|\-\)/-/g')
}

# Use this to easily matching strings based on glob pettern, without
# adding a Bash dependency (keep it vanilla Bourne-style shell).
fnmatch() # PATTERN STRING
{
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
}
