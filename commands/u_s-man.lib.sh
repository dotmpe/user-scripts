#!/usr/bin/env bash

# Assemble, convert or access User-Scripts man pages

u_s_man() #
{
  print_err error "" "This is u-s man. Use help [TOPIC] or topics to access local manual sources."
  return 1
}

build_manual () # Section Topic
{
  pandoc -s -f markdown+definition_lists+pandoc_title_block -t man  "$@"
}

build_manual_src_parts () # Section Topic
{
  local fmt src section=$1 topic=$2

  { grep "^[^# ]\+ $section $topic\($\| [^ ]\+\)" $U_S_MAN ||
      $LOG warn "" "No source for manual" "$topic($section)" 120
  } | {
    while read fmt section topic src parts
    do
      true "${src:="$topic"}"
      for part in $parts
      do
        build-ifchange src/$fmt/man/$src-$part.$fmt || {
          build-keep-going || return
        }
      done
      build_manual src/$fmt/man/$src*.$fmt
    done
  }
}

build_manuals ()
{
  local section topic
  read_nix_style_file $U_S_MAN | while read _ section topic _
  do
    build-ifchange src/man/man$section/$topic.$section
  done
  true "${sh_libs_list:="$REDO_BASE/.cllct/src/sh-libs.list"}"
  sort -u "$sh_libs_list" | while read lib_id src
  do
    sh_lib_base="$REDO_BASE/.cllct/src/functions/$lib_id-lib"
    sh_lib_list="$sh_lib_base.func-list"
    build-ifchange $REDO_BASE/src/man/man7/User-Script:$lib_id.7
  done
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
