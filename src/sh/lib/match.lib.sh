#!/bin/sh

## RegEx strings


match_lib__load ()
{
  # TODO: load name/var patterns and match rules from files, see match-htd
  : "${match_local_nametab:=table.names}"
  : "${match_local_vartab:=table.vars}"
}

match_lib__init()
{
  test -z "${match_lib_init:-}" || return $_
  #test -n "${INIT_LOG-}" || return 109
  case "${OS_UNAME,,}" in
      #darwin ) gsed=gsed; ggrep=ggrep;;
      linux ) gsed=sed; ggrep=grep ;;
      * ) command -v gsed >/dev/null 2>&1 ||
          $LOG "error" "" "GNU toolkit required" "$OS_UNAME" 100 || return
        gsed=gsed; ggrep=ggrep;;
  esac
  test ! -e "${match_local_nametab:?}" || MATCH_NAMETAB=$_
  test ! -e "${match_local_vartab:?}" || MATCH_VARTAB=$_
  #$INIT_LOG info "" "Loaded match.lib" "$0"
}


match_bre_str ()
{
  local old_lc_collate=$LC_COLLATE
  LC_COLLATE=C

  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
      ( [\\^.$*\[\]] ) printf '\%s' "$c" ;;
      ( * ) printf '%s' "$c" ;;
    esac
  done

  LC_COLLATE=$old_lc_collate
}

match_egrep () # ~ <String> <...>
{
  local old_lc_collate=$LC_COLLATE
  LC_COLLATE=C
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
      ( [?*+{}\(\).\[\]\|\ ] ) printf '\%s' "$c" ;;
      ( * ) printf '%s' "$c" ;;
    esac
  done
  LC_COLLATE=$old_lc_collate
}

# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test. This is basic regular expressions (BRE), see
# match-egrep for 'extended' regular expressions.
match_grep () # ~ <String> <...>
{
  local old_lc_collate=$LC_COLLATE
  LC_COLLATE=C
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
      ( [A-Za-z0-9{}\(\),?!@+_\"\'-] ) printf '%s' "$c" ;;
      ( * ) printf '\%s' "$c" ;;
    esac
  done
  LC_COLLATE=$old_lc_collate
}

match_grep_old ()
{
  ${gsed:-sed} -E 's/([^A-Za-z0-9{}(),?!@+_-])/\\\1/g' <<< "${1:?}"
}


# To escape filenames and perhaps other values for use as grep literals
match_grep_pattern_test ()
{
  p_="$(match_grep "$1")"
  # test regex
  echo "$1" | grep -q "^$p_$" || {
    error "cannot build regex for $1: $p_"
    return 1
  }
}

match_re_argsor () # ~ <Strings...> # Build 'or' match group from literal string arguments
{
  declare -a choices
  while test 0 -lt $#
  do
    if_ok "$(match_re_str "${1:-}")" || return
    choices+=( "$_" )
    shift
  done
  : "${choices[*]}"
  echo "(${_// /|})"
}

match_re_str () # ~ <String> <...>
{
  local old_lc_collate=$LC_COLLATE
  LC_COLLATE=C

  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
      ( [\\^.$*?+\[\]\{\}\(\)] ) printf '\%s' "$c" ;;
      ( * ) printf '%s' "$c" ;;
    esac
  done

  LC_COLLATE=$old_lc_collate
}

match_stdin () # (stdin) ~ <Regex> <Match-group> # Match lines on stdin
{
  declare line
  while read -r line
  do
    [[ "$line" =~ ${1:?} ]] || continue
    echo "${BASH_REMATCH[${2:-0}]}"
  done
}

#
