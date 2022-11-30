#!/usr/bin/env bash

## User-Scripts man routines
# Assemble, convert or access User-Scripts man pages

#u_s_man_lib_load ()
#{
# XXX: see tools/sh/env.sh
  : "${U_S_MAN:="$U_S/src/md/manuals.list"}"
#}

u_s_man () #
{
  print_err error "" "This is u-s man. Use help [TOPIC] or topics to access local manual sources."
  return 1
}

# Turn Markdown into man file
build_manual_page () # ~ Md-Manual-Doc
{
  pandoc -s -f markdown+definition_lists+pandoc_title_block -t man  "$@"
}

# Main part of src/man/man*/*.*.do. Read manuals.list config (U_S_MAN) and
# invoke each sub-target build part.
build_manual_src_parts () # ~ Section Topic
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
      build_manual_page src/$fmt/man/$src*.$fmt
    done
  }
}

# Redo target entry-point
build_manuals () # [U_S_MAN] [REDO_BASE] ~
{
  local section topic

  build-ifchange $( read_nix_style_file $U_S_MAN | while read _ section topic _
		do echo "src/man/man$section/$topic.$section"; done | tr '\n' ' ')
  true "${sh_libs_list:="$REDO_BASE/.meta/src/sh-libs.list"}"

  build-ifchange $( sort -u "$sh_libs_list" | while read lib_id src
		do
			sh_lib_base="$REDO_BASE/.meta/src/functions/$lib_id-lib"
			sh_lib_list="$sh_lib_base.func-list"
			echo "$REDO_BASE/src/man/man7/User-Script:$lib_id.7"
		done | tr '\n' ' ' )
}

# XXX: topic should be parts of files, not file names? Like commands. #MJfc
topics () # [U_S] ~
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
print_topic ()
{
  test $# -ge 1 -a $# -le 2 || return 64

  local name="$1" section

  test -n "${2:-}" && {
    section=$1 name=$2
    set -- $U_S/src/man/$1/$2.md
  } || {
    for section in 1 2 3 4 5 6 7 8
    do
      set -- $U_S/src/man/$section/$1.md
      test -e $1 || continue
      break
    done
    test -e "$1" || set -- $U_S/src/man/$name.md
    test -e "$1" || set -- $name
  }

  test -e "$1" || {
    $LOG error "" "Found no entry" "$1" 1
    print_usage
    return 1
  }

  #/usr/bin/groff -Tps -mandoc

  test -x "$(which pandoc)" || {
    $LOG "warn" "" "Install pandoc for source-man view"
    cat "$@"
    return
  }
  case "$uname" in

    Darwin ) {
      pandoc -s -f markdown -t man "$@" || return
    } | groff -T utf8 -man | less ;;

    Linux ) pandoc -s -f markdown -t man "$@" || return ;;

    * ) $LOG "error" "" "Unexpected uname" "$uname" 1 ;;
  esac
}
