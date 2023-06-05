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
  case "${uname,,}" in
      #darwin ) gsed=gsed; ggrep=ggrep;;
      linux ) gsed=sed; ggrep=grep ;;
      * ) command -v gsed >/dev/null 2>&1 ||
          $LOG "error" "" "GNU toolkit required" "$uname" 100 || return
        gsed=gsed; ggrep=ggrep;;
  esac
  test ! -e "${match_local_nametab:?}" || MATCH_NAMETAB=$_
  test ! -e "${match_local_vartab:?}" || MATCH_VARTAB=$_
  #$INIT_LOG info "" "Loaded match.lib" "$0"
}


# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep () # ~ <String>
{
  local old_lc_collate=$LC_COLLATE
  LC_COLLATE=C

  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
      ( [A-Za-z0-9{}\(\),?!@+_-] ) printf '%s' "$c" ;;
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

#
