#!/bin/sh

gotovolroot() # [Enable-Source]
{
  cd "$(pwd -P)"
  while true
  do
    test -e ./.volumes.sh || {
      test "$PWD" != "/" || return 1
      cd ..
      continue
    }
    test -z "$1" || . ./.volumes.sh
    break
  done
}

# Find volume disk-id and part-idx by looking for .volumes.sh at root
get_cwd_volume_id() # [DIR] [SEP]
{
  local cwd=$(pwd) r=
  test -n "$2" || set -- "$1" "-"
  test -n "$1" || cd "$1"
  gotovolroot 1 &&
      printf "$volumes_main_disk_index$2$volumes_main_part_index" || r=$?
  test -n "$1" || cd "$cwd"
  return $r
}
