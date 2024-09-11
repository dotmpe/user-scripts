#!/usr/bin/env bash

# Set env for str.lib.sh
str_lib__load()
{
  if [[ "${str_lib_init-}" = "0" ]]
  then
    [[ "$LOG" && ( -x "$LOG" || "$(type -t "$LOG")" = "function" ) ]] \
      && str_lib_log="$LOG" || str_lib_log="$INIT_LOG"
    [[ "$str_lib_log" ]] || return 108

    case "${OS_UNAME:?}" in
        Darwin ) expr=bash-substr ;;
        Linux ) expr=sh-substr ;;
        * ) $str_lib_log error "str" "Unable to init expr for '$OS_UNAME'" "" 1;;
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
  test -z "${str_lib_init-}" || return $_
  [[ -x "$(command -v php)" ]] && bin_php=1 || bin_php=0
  # Derived (and known extension) libs (fun sets)
  #: "${str_uc_fun:=}"
  #: "${str_htd_fun:=}"

  ! sys_debug -dev -debug -init ||
    ${INIT_LOG:?} notice "" "Initialized str.lib" "$(sys_debug_tag --oneline)"
}


str_append () # ~ <Var-name> <Value> ... # Concat value to string at var, using str-fs=' '
{
  : source "str.lib.sh"
  str_vconcat "$@"
}

# Turn '--' seperated argument seq. into lines
str_arg_seqs () # ~ <Arg-seq...> [ -- <Arg-seq> ]
{
  local exec=
  while test $# -gt 0
  do
    test "$1" = "--" && { echo "$exec"; exec=; shift; continue; }
    test -n "$exec" && exec="$exec $1" || exec="$1"
    shift
  done
  test -z "$exec" || echo "$exec"
}

str_sid () # ~ <String>
{
  : source "str.lib.sh"
  str_id "$1" _- -
}

# A more complicated str-word, with additional inputs
str_id () # ~ <String> <Extra-chars> <Subst-char> ...
{
  : source "str.lib.sh"
  : "${1:?}"
  [[ ! ${US_EXTRA_CHAR-} ]] && : "$1" ||
    : "${1//[${US_EXTRA_CHAR-:,.}]/${3:-_}${3:-_}}"
  : "${_//[^A-Za-z0-9${2:-_}]/${3:-_}}"
  "${upper:-false}" "$_" &&
  echo "${_^^}" || {
    "${lower:-false}" "$_" &&
      echo "${_,,}" ||
      echo "$_"
  }
}

# A tag? Simple character limiter using shell replace and char-range matching.
# See (notes on) URL/URN RFC's as well, in particular the special separator
# sets.
str_tag () # <String> # Transform string to tag
{
  : source "str.lib.sh"
  echo "${1//[^A-Za-z0-9%+-]/-}"
}

str_vawords () # ~ <Variables...> # Transform strings to words
{
  : source "str.lib.sh"
  declare -n v
  for v
  do v="${v//[^A-Za-z0-9_]/_}"
  done
}

str_vconcat () # ~ <Var-name> <Str> ... # Append at end, concatenating with str-fs=' as separator
{
  : source "str.lib.sh"
  declare -n ref=${1:?"$(sys_exc str.lib:str-append:ref@_1 "Variable name expected")"}
  #: ${ref:?"$(sys_exc str.lib:str-append:ref@_1 "Variable name expected")"}
  ref="${ref-}${ref:+${str_fs- }}${2:?"$(sys_exc str.lib:str-append "")"}"
}

str_vtag () # <Var> [<String>] # Transform string to tag
{
  : source "str.lib.sh"
  declare -n v=${1:?}
  : "${2-$v}"
  v="${_//[^A-Za-z0-9%+-]/-}"
}

str_vword () # ~ <Variable> [<String>] # Transform string to word
{
  : source "str.lib.sh"
  declare -n v=${1:?}
  : "${2-$v}"
  v="${_//[^A-Za-z0-9_]/_}"
}

# Restrict used characters to 'word' class (alpha numeric and underscore)
str_word () # ~ <String> # Transform string to word
{
  : source "str.lib.sh"
  : "${1:?}"
  : "${_//[^A-Za-z0-9_]/_}"
  "${upper:-false}" "$_" &&
  echo "${_^^}" || {
    "${lower:-false}" "$_" &&
      echo "${_,,}" ||
      echo "$_"
  }
}

str_words () # ~ <Strings...> # Transform strings to words
{
  : source "str.lib.sh"
  declare str
  for str
  do
    echo "${str//[^A-Za-z0-9_]/_}"
  done
}

# x-platform regex match since Bash/BSD test wont chooche on older osx
x_re()
{
  : source "str.lib.sh"
  echo $1 | grep -E "^$2$" > /dev/null && return 0 || return 1
}

# Use this to easily matching strings based on glob pettern, without
# adding a Bash dependency (keep it vanilla Bourne-style shell).
fnmatch() # PATTERN STRING
{
  : source "str.lib.sh"
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
}
# Derive: str-globmatch

fnmatch_any () # STRING... -- PATTERNS...
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
  [[ $# -eq 2 ]] || return 99
  awk -vFS="" -vOFS="" '{$'"$2"'=$'"$2"'"'"$1"'"}1'
}

# Insert tab-character at x position (sed)
sed_insert_char() # Char Line-Chars-Offset
{
  : source "str.lib.sh"
  [[ $# -eq 2 ]] || return 99
  sed 's/./&'"$1"'/'"$3"
}

# Remove last n chars from stream at stdin
strip_last_nchars() # Num
{
  : source "str.lib.sh"
  rev | cut -c $(( 1 + $1 ))- | rev
}

# Join lines in file based on first field
# See https://unix.stackexchange.com/questions/193748/join-lines-of-text-with-repeated-beginning
join_lines() # [Src] [Delim]
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
  [[ "$expr" ]] || error "expr init req" 1
  case "$expr" in
      sh-substr )
          expr substr "$1" "$2" "$3" ;;
      bash-substr )
          bash -c 'MYVAR=_"'"$1"'"; printf -- "${MYVAR:'$2':'$3'}"' ;;
      * ) error "unable to substr $expr" 1
  esac
}

str_collapse () # ~ <String> <Char> # Use glob replate
{
  : source "str.lib.sh"
  declare char=${2:?}
  str_glob_replace "${1:?}" "$char$char" "$char"
}

# Unlike normal glob substitution repeat operation on result, rewriting the
# entire string until it no longer matches glob.
str_glob_replace () # ~ <String> <Glob> <Substitute> # Replace until no more matches are found
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
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
  : source "str.lib.sh"
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
str_globstripcl () # ~ <Str> [<Glob-c>] ...
{
  : source "str.lib.sh"
  local prefc=${2:-"[ ]"} str="${1:?}"
  while str_globmatch "$str" "$prefc*"
  do
    str="${str#$prefc}"
    [[ "$str" ]] || break
  done
  echo "$str"
}

str_globstripcr () # ~ <Str> [<Glob-c>] ...
{
  : source "str.lib.sh"
  local prefc=${2:-"[ ]"} str="${1:?}"
  while str_globmatch "$str" "*$prefc"
  do
    str="${str%$prefc}"
    [[ "$str" ]] || break
  done
  echo "$str"
}

str_indent () # (s) ~ [<Indentation>] ...
{
  : source "str.lib.sh"
  str_prefix "${1:-  }"
}

# Concatenate all Strings, using Sep as separation string. Concat or any string
# can be left empty (an empty concat or string will be concatenated).
str_join () # ~ <Sep> <Strings...>
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
  declare c=${1?} s && shift && : "" &&
  for s
  do : "${_:+$_${s:+$c}}$s"
  done &&
  echo "$_"
}

str_prefix () # (s) ~ <Prefix-str> ...
{
  : source "str.lib.sh"
  local str prefix=${1:?"$(sys_exc str-prefix:str@_1 "Prefix string expected")"}
  while read -r str
  do echo "${prefix}${str}"
  done
}

str_suffix () # (s) ~ <Suffix-str> ...
{
  : source "str.lib.sh"
  local str suffix=${1:?"$(sys_exc str-suffix:str@_1 "Suffix string expected")"}
  while read -r str
  do echo "${str}${suffix}"
  done
}

str_quote () # ~ <String> ...
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
  while IFS=${1:-=}$'\n' read -r key value
  do
    if_ok "$(str_quote "$value")" &&
    printf '%s=%s\n' "$key" "$_" || return
  done
}

str_quote_var ()
{
  : source "str.lib.sh"
  echo "$( printf '%s' "$1" | grep -o '^[^=]*' )=$(str_quote "$( printf -- '%s' "$1" | sed 's/^[^=]*=//' )")"
}

str_rematch ()
{
  : source "str.lib.sh"
  [[ $1 =~ $2 ]]
}

str_trim ()
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
  [[ 0 -lt $# ]] || return ${_E_MA:-194}
  declare str_sws=${str_sws:-"[\n\t ]"}
  while [[ 0 -lt $# ]]
  do
    : "${1#$str_sws}" &&
    : "${_%$str_sws}" &&
    echo "$_" && shift || return
  done
}

str_vid () # ~ <Var> [<String-value>]
{
  : source "str.lib.sh"
  local -n __str_vid=${1:?} &&
  __str_vid=$(str_id "${2:-${__str_vid}}")
}

# XXX: str-fs is used to set element separator
str_wordmatch () # ~ <Word> <Strings...> # Non-zero unless word appears
{
  : source "str.lib.sh"
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
  : source "str.lib.sh"
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

strfmt_hashtab () # ~ <Printfmt> <Assoc-arr> # printf for associative arrays
{
  : source "str.lib.sh"
  # Cannot have by-reference array var, so instead use eval macro to refer to
  # dynamic but global array name
  local key fmt=${1:?} arr=${2:?}
  eval "
    local key
    for key in \"\${!${arr}[@]}\"
    do
      printf \"$fmt\" \"\$key\" \"\${${arr}[\"\$key\"]}\"
    done
  "
}


strfmt_printf () # ~ <printf-fmt> <printf-args...>
{
  : source "str.lib.sh"
  printf -- "$@"
}

#
