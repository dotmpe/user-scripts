#!/bin/sh

__box_run_args() # Script-Cmd {Script-Args...]
{
  __box_find_script
}

__box_info()
{
  echo TODO info about find-script
}

__box_find_script()
{
  true
  # 1. If not global start looking for run.lib.sh and run.d
  #    There may be prefixes for local paths to be tried too.
  # 2. If global or not found, look for builtin or root-level run.d
}

