#!/usr/bin/env bats

base=main.lib
load ../init

setup()
{
  init
}


@test "$base: SHT-PWD" {

  test -n "$SHT_PWD" -a -d "$SHT_PWD"
}


@test "$base: try-exec-func (bash) on existing function" {

  skip

  run bash -c "$(cat <<EOM

__load_mode=boot source $scriptpath/tools/sh/init.sh &&
source '$main_inc' &&
try_exec_func mytest_function
EOM
    )"
  diag "Output: ${lines[0]}"
  {
    test $status -eq 0 &&
    fnmatch "mytest" "${lines[*]}"
  } || stdfail 3.
}
