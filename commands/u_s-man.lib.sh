#!/usr/bin/env bash


u_s_man() #
{
  print_err error "" "This is u-s man. Use help [TOPIC] or topics to access local manual sources."
  return 1
}

# XXX: topic should be parts of files, not file names? Like commands. #MJfc
topics() #
{
  test $# -eq 0 || return 99
  local base="$U_S/src/man/"

  for sec in 1 2 3 4 5 6 7 8
  do
    test "$base$sec/*.md" != "$(echo $base$sec/*.md)" || continue
    for y in $base$sec/*.md
    do echo "$(basename -- "$y" .md) ($sec)"
    done
  done | sort
}

# TODO: print topic for section properly, sort content into sections. #MJfc
print_topic()
{
  test $# -ge 1 -a $# -le 2 || return 99

  local name= section=

  test -n "$2" && {
    name=$2 section=$1
    set -- $U_S/src/man/$1/$2.md

  } || {
    for section in 1 2 3 4 5 6 7 8
    do
      test -e $U_S/src/man/$section/$1.md || continue
      set -- $U_S/src/man/$section/$1.md
      name=$1
      break
    done
  }

  test -e "$1" || set -- $U_S/src/man/$name.md
  test -e "$1" || $LOG error "" "Found no entry" "$1" 1

  #/usr/bin/groff -Tps -mandoc

  test -x "$(which pandoc)" && {
  case "$uname" in

    darwin ) pandoc -s -f markdown -t man "$@" | groff -T utf8 -man | less
      ;;
    linux ) pandoc -s -f markdown -t man "$@"
      ;;
    * ) $LOG "error" "" "uname" "$uname"
      ;;
  esac
  } || {
    $LOG "warn" "" "Install pandoc for source-man view"
    cat "$@"
  }
}
