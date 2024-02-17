#!/bin/sh


# Set env for str.lib.sh
str_lib__load()
{
  test "${str_lib_init-}" = "0" || {
    test -n "$LOG" -a \( -x "$LOG" -o "$(type -t "$LOG")" = "function" \) \
      && str_lib_log="$LOG" || str_lib_log="$INIT_LOG"
    test -n "$str_lib_log" || return 108

    case "$uname" in
        Darwin ) expr=bash-substr ;;
        Linux ) expr=sh-substr ;;
        * ) $str_lib_log error "str" "Unable to init expr for '$uname'" "" 1;;
    esac

    test -n "${ext_groupglob-}" || {
      test "$(echo {foo,bar}-{el,baz})" != "{foo,bar}-{el,baz}" \
            && ext_groupglob=1 \
            || ext_groupglob=0
      # FIXME: part of [vc.bash:ps1] so need to fix/disable verbosity
      #debug "Initialized ext_groupglob=$ext_groupglob"
    }

    test -n "${ext_sh_sub-}" || ext_sh_sub=0

    # XXX:
  #      echo "${1/$2/$3}" ... =
  #        && ext_sh_sub=1 \
  #        || ext_sh_sub=0
  #  #debug "Initialized ext_sh_sub=$ext_sh_sub"
  }
}

str_lib__init()
{
  test -x "$(command -v php)" && bin_php=1 || bin_php=0
}


str_vawords () # ~ <Var-names...>
{
  typeset var
  for var
  do str_vword $var
  done
}

str_vword () # ~ <Var-name>
{
  typeset -n v=${1:?}
  v="${v//[^A-Za-z0-9_]/_}"
}

str_word () # ~ <Str>
{
  echo "${1//[^A-Za-z0-9_]/_}"
}

str_words () # ~ <Strings...>
{
  typeset str
  for str
  do
    echo "${str//[^A-Za-z0-9_]/_}"
  done
}

# ID for simple strings without special characters
mkid() # Str Extra-Chars Substitute-Char
{
  local s="${2-}" c="${3-}"
  # Use empty c if given explicitly, else default
  test $# -gt 2 || c='\.\\\/:_'
  test -n "$s" || s=-
  test -n "${upper-}" && {
    trueish "${upper-}" && {
      id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" | tr '[:lower:]' '[:upper:]')
    } || {
      id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" | tr '[:upper:]' '[:lower:]')
    }
  } || {
    id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" )
  }
}

# to filter strings to variable id name
mkvid () # STR
{
  true "${1:?}"
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]+$ ]] && test -z "${upper:-}" && {
    vid="$1"
    return
  }
  trueish "${upper-}" && {
    vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g' | tr '[:lower:]' '[:upper:]')
    return
  }
  falseish "${upper-}" && {
    vid=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g' | tr '[:upper:]' '[:lower:]')
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
# Derive: str-globmatch

fnmatch_any () # STRING... -- PATTERNS...
{
  local str=; while args_has_next "$@"; do str="${str:-}${str:+" "}$1"; shift;
  done; shift
  while test $# -gt 0
  do
    fnmatch "$1" "$str" && return
    shift
    continue
  done
  return 1
}

# Insert tab-character at x position (awk)
awk_insert_char() # Char Line-Chars-Offset
{
  test $# -eq 2 || return 99
  awk -vFS="" -vOFS="" '{$'"$2"'=$'"$2"'"'"$1"'"}1'
}

# Insert tab-character at x position (sed)
sed_insert_char() # Char Line-Chars-Offset
{
  test $# -eq 2 || return 99
  sed 's/./&'"$1"'/'"$3"
}

# Remove last n chars from stream at stdin
strip_last_nchars() # Num
{
  rev | cut -c $(( 1 + $1 ))- | rev
}

# Join lines in file based on first field
# See https://unix.stackexchange.com/questions/193748/join-lines-of-text-with-repeated-beginning
join_lines() # [Src] [Delim]
{
  test -n "${1-}" || set -- "-" "${2-}"
  test -n "${2-}" || set -- "$1" " "
  test "-" = "$1" -o -e "$1" || error "join-lines: file expected '$1'" 1

  # use awk to build array of paths, for basename
  awk '{
		k=$2
		for (i=3;i<=NF;i++)
			k=k "'"$2"'" $i
		if (! a[$1])
			a[$1]=k
		else
			a[$1]=a[$1] "'"$2"'" k
	}
	END{
		for (i in a)
			print i "'"$2"'" a[i]
	}' "$1"
}

expr_substr()
{
  test -n "$expr" || error "expr init req" 1
  case "$expr" in
      sh-substr )
          expr substr "$1" "$2" "$3" ;;
      bash-substr )
          bash -c 'MYVAR=_"'"$1"'"; printf -- "${MYVAR:'$2':'$3'}"' ;;
      * ) error "unable to substr $expr" 1
  esac
}

str_collapse ()
{
  declare char=${2:?}
  str_glob_replace "${1:?}" "$char$char" "$char"
}

str_glob_replace ()
{
  declare str=${1:?} glob="${2:?}" sub=${3:?}
  while str_globmatch "$str" "*$glob*"
  do
    str="${str//$glob/$sub}"
  done
  echo "$str"
}

str_globmatch () # ~ <String> <Glob-patterns...>
{
  test 2 -le $# || return ${_E_GAE:-193}
  declare str=${1:?}
  shift
  while test $# -gt 0
  do
    case "$str" in ( ${1:?} ) return ;; * ) ${any:-true} || return 1 ;; esac
    shift
  done
  return 1
}

# String-strip based on glob. Removes all matching characters at the left. This
# is useful because the standard parameter expansions only do shortest and
# longest match but not repeated matches.
str_globstripcl () # ~ <Str> [<Glob-c>]
{
  local prefc=${2:-"[ ]"} str="${1:?}"
  while str_globmatch "$str" "$prefc*"
  do
    str="${str#$prefc}"
  done
  echo "$str"
}

str_globstripcr () # ~ <Str> [<Glob-c>]
{
  local prefc=${2:-"[ ]"} str="${1:?}"
  while str_globmatch "$str" "*$prefc"
  do
    str="${str%$prefc}"
  done
  echo "$str"
}

# Combine all Strings, using Concat as separation string
str_join () # ~ <Concat> <Strings...>
{
  typeset c=${1:?} s=${2-} && shift 2 &&
  : "$s" &&
  for s
  do : "$_$c$s"
  done &&
  echo "$_"
}

# Like str-join but ignore empty Strings during concatenation
str_ejoin () # ~ <Concat> <Strings...>
{
  typeset c=${1:?} s && shift && : "" &&
  for s
  do : "${_:+$_${s:+$c}}$s"
  done &&
  echo "$_"
}

str_quote ()
{
  case "$1" in
    ( "" ) printf '""' ;;
    ( *" "* | *[\[\]\<\>$]* )
      case "$1" in
          ( *"'"* ) printf '"%s"' "$1" ;;
          ( * ) printf "'%s'" "$1" ;;
      esac ;;
    ( * ) printf '%s' "$1" ;;
  esac
}

str_quote_kvpairs () # ~ [<Src-asgn-sep>]
{
  while IFS=${1:-=}$'\n' read -r key value
  do
    if_ok "$(str_quote "$value")" &&
    printf '%s=%s\n' "$key" "$_" || return
  done
}

str_quote_var ()
{
  echo "$( printf '%s' "$1" | grep -o '^[^=]*' )=$(str_quote "$( printf -- '%s' "$1" | sed 's/^[^=]*=//' )")"
}

str_trim ()
{
  test 0 -lt $# || return ${_E_MA:-194}
  declare str_sws=${str_sws:-"[\n\t ]"}
  while test 0 -lt $#
  do
    if_ok "$(str_globstripcl "$1" "$str_sws")" &&
    if_ok "$(str_globstripcr "$_" "$str_sws")" &&
    echo "$_" && shift || return
  done
}

str_trim1 ()
{
  test 0 -lt $# || return ${_E_MA:-194}
  declare str_sws=${str_sws:-"[\n\t ]"}
  while test 0 -lt $#
  do
    : "${1#$str_sws}" &&
    : "${_%$str_sws}" &&
    echo "$_" && shift || return
  done
}

str_wordmatch () # ~ <Word> <Strings...> # Non-zero unless word appears
{
  test 0 -lt $# || return ${_E_MA:-194}
  test 2 -le $# || return ${_E_GAE:-193}
  local str_fs=${str_fs:- } words="${*:2}"
  test "$str_fs" = " " || words=${words// /$str_fs}
  case "$str_fs$words$str_fs" in
    ( *"$str_fs${1:?}$str_fs"*) ;;
      * ) false ; esac
}

str_wordsmatch () # ~ <String> <Words...> #
{
  test 0 -lt $# || return ${_E_MA:-194}
  test 2 -le $# || return ${_E_GAE:-193}
  local str_fs=${str_fs:- } word
  for word in "${@:2}"
  do
    case "$str_fs${1:?}$str_fs" in
      ( *"$str_fs${word:?}$str_fs"*) return ;;
        * ) continue ; esac
  done
  false
}

#
