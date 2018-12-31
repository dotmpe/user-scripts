#!/bin/sh

match_lib_init()
{
  test -n "$INIT_LOG" || return 102

  test -n "$uname" || uname=$(uname -s)
  case "$uname" in
      Darwin ) gsed=gsed; ggrep=ggrep;;
      Linux ) gsed=sed; ggrep=grep ;;
      * ) $LOG "error" "" "GNU toolkit required" "$uname" 100
  esac

  $INIT_LOG info "" "Loaded match.lib" "$0"
}


# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep() # String
{
  echo "$1" | $gsed -E 's/([^A-Za-z0-9{}(),?!@+_])/\\\1/g'
}


# To escape filenames and perhaps other values for use as grep literals
match_grep_pattern_test()
{
  p_="$(match_grep "$1")"
  # test regex
  echo "$1" | grep -q "^$p_$" || {
    error "cannot build regex for $1: $p_"
    return 1
  }
}
