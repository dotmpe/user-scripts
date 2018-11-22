#!/bin/sh

gotovolroot()
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

get_cwd_volume_id()
{
  test -n "$1" || set -- .
  gotovolroot 1 || return
  printf "$volumes_main_disk_index$1$volumes_main_part_index"
  return
}
