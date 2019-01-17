#!/bin/sh


composure_lib_load()
{
  test -n "$COMPOSURE" || COMPOSURE=$HOME/.local/composure
}

composure_lib_init()
{
  test -n "$COMPOSURE" && # assert Expected Composure user setting
  test -d "$COMPOSURE" # assert Expected Composure user dir
}

composure_check_name_scripts()
{
  for inc in $COMPOSURE/*.inc
  do
    fnmatch "$(basename -- "$inc" .inc)[ (]*" "$(head -1 $inc)" ||
      error "Name mismatch on $inc: $(head -n 1 $inc)" 1
  done
}

composure_list_names()
{
  ls $COMPOSURE/*.inc | exts=.inc act=basenames foreach_do
}

is_composer_inc()
{
  test -s "$COMPOSURE/$1.inc" || return
}

composure_shlib_load()
{
  lib_load functions
}

# Compare composure inc with function-lines from lib file, if they are
# different update one or merge if possible.
composure_shlib_sync() # Func-Name Lib-File
{
  is_composer_inc "$1" || return
  echo "$@" | composure_shlib_sync_pairs
}

composure_shlib_func_id() # Func-Name Lib-File
{
  # function_copy TODO: test copy-function wrapper using builtins before lib lookup
  copy_function "$@" | ck_sha1 -
}

composure_shlib_sync_pairs() # [create] [force] ~
{
  grep_nix_lines | while read fname libfile ; do
    is_composer_inc "$fname" || {
      trueish "$create" || {
        trueish "$force" || error "No such composer inc '$fname'" 1
        warn "No such composer inc '$fname', ignored (--force)"
        continue
      }
      composure_draft "$fname" || return
      # No need for sync
      continue
    }

    composure_shlib_func_id "$fname" "$libfile"

    echo "$1: "
    cat "$COMPOSURE/$1.inc"
  done
}
