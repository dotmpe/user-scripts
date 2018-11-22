#!/bin/sh


# Set env for str.lib.sh
str_lib_load()
{
  test -n "$uname" || uname="$(uname -s)"
  case "$uname" in
      Darwin ) expr=bash-substr ;;
      Linux ) expr=sh-substr ;;
      * ) error "Unable to init expr for '$uname'" 1;;
  esac

  test -n "$ext_groupglob" || {
    test "$(echo {foo,bar}-{el,baz})" != "{foo,bar}-{el,baz}" \
          && ext_groupglob=1 \
          || ext_groupglob=0
    # FIXME: part of [vc.bash:ps1] so need to fix/disable verbosity
    #debug "Initialized ext_groupglob=$ext_groupglob"
  }

  test -n "$ext_sh_sub" || ext_sh_sub=0

  #      echo "${1/$2/$3}" ... =
  #        && ext_sh_sub=1 \
  #        || ext_sh_sub=0
  #  #debug "Initialized ext_sh_sub=$ext_sh_sub"
  #}

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


# x-platform regex match since Bash/BSD test wont chooche on older osx
x_re()
{
  echo $1 | grep -E "^$2$" > /dev/null && return 0 || return 1
}

# Use this to easily matching strings based on glob pettern, without
# adding a Bash dependency (keep it vanilla Bourne-style shell).
fnmatch() # PATTERN STRING
{
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
}

# Remove last n chars from stream at stdin
strip_last_nchars() # Num
{
  rev | cut -c $(( 1 + $1 ))- | rev
}
