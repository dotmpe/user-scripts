#!/bin/sh


# Set env for str.lib.sh
str_lib__load()
{
  if [[ "${str_lib_init-}" = "0" ]]
  then
    [[ "$LOG" && ( -x "$LOG" || "$(type -t "$LOG")" = "function" ) ]] \
      && str_lib_log="$LOG" || str_lib_log="$INIT_LOG"
    [[ "$str_lib_log" ]] || return 108

    case "$uname" in
        Darwin ) expr=bash-substr ;;
        Linux ) expr=sh-substr ;;
        * ) $str_lib_log error "str" "Unable to init expr for '$uname'" "" 1;;
    esac

    [[ "${ext_groupglob-}" ]] || {
      [[ "$(echo {foo,bar}-{el,baz})" != "{foo,bar}-{el,baz}" ]] \
            && ext_groupglob=1 \
            || ext_groupglob=0
      # FIXME: part of [vc.bash:ps1] so need to fix/disable verbosity
      #debug "Initialized ext_groupglob=$ext_groupglob"
    }

    [[ "${ext_sh_sub-}" ]] || ext_sh_sub=0

    # XXX:
  #      echo "${1/$2/$3}" ... =
  #        && ext_sh_sub=1 \
  #        || ext_sh_sub=0
  #  #debug "Initialized ext_sh_sub=$ext_sh_sub"
  fi
}

str_lib__init()
{
  [[ -x "$(command -v php)" ]] && bin_php=1 || bin_php=0
}


str_append () # ~ <Var-name> <Value> ...
{
  declare -n ref=${1:?"$(sys_exc str.lib:str-append:ref@_1 "Variable name expected")"}
  #: ${ref:?"$(sys_exc str.lib:str-append:ref@_1 "Variable name expected")"}
  ref="${ref-}${ref:+${str_fs- }}${2:?"$(sys_exc str.lib:str-append "")"}"
}

str_vawords () # ~ <Variables...> # Transform strings to words
{
  declare -n v
  for v
  do v="${v//[^A-Za-z0-9_]/_}"
  done
}

# A tag? See URL/URN RFC's as well...
str_tag () # <String> # Transform string to tag
{
  echo "${1//[^A-Za-z0-9%+-]/-}"
}

str_vtag () # <Var> <String> # Transform string to tag
{
  declare -n v=${1:?}
  v="${v//[^A-Za-z0-9%+-]/-}"
}

str_vword () # ~ <Variable> # Transform string to word
{
  declare -n v=${1:?}
  v="${v//[^A-Za-z0-9_]/_}"
}

# Restrict used characters to 'word' class (alpha numeric and underscore)
str_word () # ~ <String> # Transform string to word
{
  echo "${1//[^A-Za-z0-9_]/_}"
}

str_words () # ~ <Strings...> # Transform strings to words
{
  declare str
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
  [[ $# -gt 2 ]] || c='\.\\\/:_'
  [[ "$s" ]] || s=-
  [[ "${upper-}" ]] && {
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
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]+$ && -z "${upper:-}" ]] && {
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
  while [[ $# -gt 0 ]]
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
  [[ $# -eq 2 ]] || return 99
  awk -vFS="" -vOFS="" '{$'"$2"'=$'"$2"'"'"$1"'"}1'
}

# Insert tab-character at x position (sed)
sed_insert_char() # Char Line-Chars-Offset
{
  [[ $# -eq 2 ]] || return 99
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
  [[ "${1-}" ]] || set -- "-" "${2-}"
  [[ "${2-}" ]] || set -- "$1" " "
  [[ "-" = "$1" || -e "$1" ]] || error "join-lines: file expected '$1'" 1

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
  [[ "$expr" ]] || error "expr init req" 1
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

# XXX: return just expanded part for single-star glob
str_glob_expansions () # ~ <Single-star-glob-expression>
{
  local glob=${1:?} glob_head glob_tail
  : "${glob%%["*"]*}"
  glob_head=${#_}
  : "${glob:$(( 1 + glob_head ))}"
  glob_tail=${#_}

  declare -a values &&
  if_ok "$(compgen -G "$glob")" &&
  <<< "$_" mapfile -t values &&
  for result in "${values[@]}"
  do
    [[ 0 -eq $glob_tail ]] && {
      echo "${result:$glob_head}"
    } || {
      len=$(( ${#result} - glob_head - glob_tail ))
      echo "${result:$glob_head:$len}"
    }
  done
}

# see also fnmatch and wordmatch
str_globmatch () # ~ <String> <Glob-patterns...>
{
  [[ 2 -le $# ]] || return ${_E_GAE:-193}
  declare str=${1:?"$(sys_exc str-globmatch:str@_1 "String expected")"}
  shift
  while [[ $# -gt 0 ]]
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
    [[ "$str" ]] || break
  done
  echo "$str"
}

str_globstripcr () # ~ <Str> [<Glob-c>]
{
  local prefc=${2:-"[ ]"} str="${1:?}"
  while str_globmatch "$str" "*$prefc"
  do
    str="${str%$prefc}"
    [[ "$str" ]] || break
  done
  echo "$str"
}

str_indent () # (s) ~ [<Indentation>]
{
  str_prefix "${1:-  }"
}

# Combine all Strings, using Concat as separation string. Concat or any string
# can be left empty (an empty concat or string will be concatenated).
str_join () # ~ <Concat> <Strings...>
{
  declare c=${1?} s=${2-} && shift 2 && : "$s" &&
  for s
  do : "$_$c$s"
  done &&
  echo "$_"
}

# Like str-join but ignore empty Strings during concatenation (concat can
# still be empty).
str_nejoin () # ~ <Concat> <Strings...>
{
  declare c=${1?} s && shift && : "" &&
  for s
  do : "${_:+$_${s:+$c}}$s"
  done &&
  echo "$_"
}

str_prefix () # (s) ~ <Prefix-str>
{
  local str prefix=${1:?}
  while read -r str
  do echo "${prefix}${str}"
  done
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

str_rematch ()
{
  [[ "$1" =~ $2 ]]
}

str_trim ()
{
  [[ 0 -lt $# ]] || return ${_E_MA:-194}
  declare str_sws=${str_sws:-"[\n\t ]"}
  while [[ 0 -lt $# ]]
  do
    if_ok "$(str_globstripcl "$1" "$str_sws")" &&
    if_ok "$(str_globstripcr "$_" "$str_sws")" &&
    echo "$_" && shift || return
  done
}

str_trim1 ()
{
  [[ 0 -lt $# ]] || return ${_E_MA:-194}
  declare str_sws=${str_sws:-"[\n\t ]"}
  while [[ 0 -lt $# ]]
  do
    : "${1#$str_sws}" &&
    : "${_%$str_sws}" &&
    echo "$_" && shift || return
  done
}

# XXX: str-fs is used to set element separator
str_wordmatch () # ~ <Word> <Strings...> # Non-zero unless word appears
{
  [[ 0 -lt $# ]] || return ${_E_MA:-194}
  [[ 2 -le $# ]] || return ${_E_GAE:-193}
  local str_fs=${str_fs:- } words="${*:2}"
  [[ "$str_fs" = " " ]] || words=${words// /$str_fs}
  case "$str_fs$words$str_fs" in
    ( *"$str_fs${1:?}$str_fs"*) ;;
      * ) false ; esac
}

str_wordsmatch () # ~ <String> <Words...> #
{
  [[ 0 -lt $# ]] || return ${_E_MA:-194}
  [[ 2 -le $# ]] || return ${_E_GAE:-193}
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
