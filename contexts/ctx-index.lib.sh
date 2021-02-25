#!/usr/bin/env bash

index_update () # Cmds... -- Select Id-Col Sort-Key Target Temp
{
  $LOG info ctx:index "index_update" "$#:$*"

  local  cmds=
  while test "$1" != '--'
  do cmds="${cmds-}${cmds+" "}$1"; shift
  done; shift
  local select="$1" id_col="$2" sort_key="$3" index="$4" cache="$5" ; shift 5
  test -n "$select" || select=index_update_select
  local new_index=
  test -e "$index" && new_index=0 || new_index=1
  set -- $cmds "$@"
  local build_sub=$1; mkvid "$1"; shift; local build_sub_cmd="$vid"; unset vid
  { $build_sub_cmd "$@" || return
  } > "$cache"

  local sort=$( IFS=, ; echo $sort_key | xargs printf -- "-k %s\n" )
  test $new_index -eq 1 && {
    true # redo wants to do this: cat $cache > $index
  } || {
    # Merge index with cache, using new or updated entries from cache
    test ! -e $cache -o $index -nt $cache || {
      index_merge "$index" "$cache"
    }
  }
}

index_merge () # Index Cache
{
  cat $2 > $2.tmp2
  ${select:="index_update_select"} ${id_col:-4} $1 $2 >$2.tmp3
  sort -t' ' ${sort:-"-k 4g"} --merge $2.tmp3 $2.tmp2 - >$2
  rm $2.tmp*
}

# Return index entries excluding those updated in cache (the new index)
index_update_select () # Id-Col Index Cache
{
  $LOG info ctx:index "index_update_select" "$#:$*"

  local ids=/tmp/cache-ids.tmp
  cut -d' ' -f$1 $3 | while read -r src
  do echo "^[0-9 \.@+-]* $(match_grep "$src")\\($\\| \\)"
  done >$ids
  grep -vf $ids $2
  rm $ids
}

# Actions: init | update-index | update-index-deleted | update-newer
files_index () # [Action] Index
{
  $LOG info ctx:index "files_index" "$#:$*"

  # FIXME: there is no need to take sort-key argument, order is hardcoded below
  local mtime action="$1" sort_key="4d" index="$2"
  shift 2
  test -n "$action" || {
    test -n "$index" -a -e "$index" && action=update-newer || action=init
  }
  test -e $index || { test $action = init || {
      $LOG error "" "Need existing index for '$action'" "$index"
      return 1
  }; }

  test -n "${generator:-}" || local generator=list_sh_files
  local sort=$( printf -- "-k %s\n" ${sort_key//,/ } )
  files_index_fetch "$action" "$index" "$generator" "$@" |
    while read -r dtime mtime ctime src rest
    do
      test ${dtime:-'-'} = - && {
        test ${mtime:-'-'} != - || mtime="@$(stat -c '%Y' "$src")"
        echo "- $mtime $ctime $src $rest"
      } ||
        echo "$dtime $mtime $ctime $src $rest"

    done | sort -t' ' $sort
}

files_index_fetch () # Action Index Generator
{
  local action=$1 index=$2 generator=$3 ; shift 3

  # Use generator to find all or newer files
  test "$action" = "update-index" || {
    case $action in
      init ) $generator "" "" "$@" ;;
      update-newer ) $generator "" "$index" "$@" ;;
    esac | while read -r src
      do echo "- @$(stat -c '%Y' "$src") - $src"
    done
  }

  # To update deletions, we'll need to check every src from index
  case "$action" in update-index | update-index-deleted )
    while read dtime mtime ctime src rest
    do
      test -e "$src" && {
        # Only for full update-index go and check mtime
        case "$action" in update-index-deleted ) continue ;; * ) ;; esac
      } || {
        test ${dtime:-'-'} != - || {
          $LOG error "" deleted "$src"
          echo "@$(date +'%s') $mtime $ctime $src $rest"
        }
        # Cannot further check non-existent file
        continue
      }
      # Update mtime
      cur_mtime=@$(stat -c '%Y' "$src")
      test ${mtime:1} -eq ${cur_mtime:1} || {
        $LOG error "" "mtime mismatch '$src'" "$mtime <> $cur_mtime"
        echo "$dtime $cur_mtime $ctime $src $rest"
      }
    done <"$index"
    return $?
  ;; esac
}


# Id: U-S:contexts/ctx-index.lib.sh                                ex:ft=bash:
