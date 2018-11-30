#!/usr/bin/env bats

base=mainlibs
load ../init

setup()
{
  case "$BATS_TEST_DESCRIPTION" in
    *"init.bash 0"* ) init 0;;
    *"init.bash"* ) init ;;
    * ) init 0 0 ;;
  esac
}


@test "$base: test framework" {

  test -n "$base" -a -n "$uname"
  echo "testpath: $testpath"
  test -n "$testpath" -a -d "$testpath"
  echo "SHT_PWD: $SHT_PWD"
  test -n "$SHT_PWD" -a -d "$SHT_PWD"

  test -s "$testpath/helper/extra.bash"
  test -s "$testpath/helper/stdtest.bash"
  test -s "$testpath/helper/assert.bash"

  echo "BATS_LIB_PATH: $BATS_LIB_PATH"
  test -n "$BATS_LIB_PATH"

  # Better tested utils shipped to avoid using baselibs during test
  run load extra
  test $status -eq 0 -a -z "${lines[*]}" || {
      printf "Status: $status\nLines:\n${lines[@]}"
      false
    }

  load extra

  # Bats test helpers
  run load stdtest
  test $status -eq 0
  test -z "${lines[*]}"

  load stdtest

  # More test helpers
  run load assert
  test_ok_empty || stdfail assert
}

@test "$base: base env" {

  echo "lib: $lib_lib_loaded"
  test -n "$lib_lib_loaded"

  load extra stdtest

  for _i in ${BATS_LIB_PATH//:/ }
  do
    test -d "$_i" || fail "existing dir expected '$_i'"
  done

  load assert

  echo "scriptpath: $scriptpath"
  assert test -n "$scriptpath"
  echo "script_util: $script_util"
  assert test -n "$script_util"
  assert test -n "$SCRIPTPATH"
  assert test -d "$scriptpath"
  assert test -e "$scriptpath/lib.lib.sh"
  assert test -d "$script_util"
  assert test -e "$script_util/init.sh"
  assert test -e "$script_util/boot/null.sh"
}

@test "$base: base libs" {

  test -z "$os_lib_loaded" -a \
    -z "$str_lib_loaded" -a \
    -z "$sys_lib_loaded"
  lib_load sys
  echo "sys: $sys_lib_loaded"
  echo "os: $sys_lib_loaded"
  echo "str: $sys_lib_loaded"
  lib_load os str
  test -n "$os_lib_loaded" -a -n "$str_lib_loaded"

  load extra stdtest

  for lib in sys os str shell logger logger-std logger-theme
  do
    run lib_load $lib
    test_ok_empty || stdfail $lib
  done
}

@test "$base: test init.bash 0" {
  type trueish >/dev/null
  type fnmatch >/dev/null
  type tmpd >/dev/null
  type tmpf >/dev/null
  type get_uuid >/dev/null
}

@test "$base: test init.bash" {

  fnmatch "* logger-std *" " $default_lib " || stdfail "$default_lib"

  test $os_lib_loaded -eq 1
  test $str_lib_loaded -eq 1
  test $sys_lib_loaded -eq 1
  test $logger_lib_loaded -eq 1

  func_exists fnmatch
  func_exists error
  func_exists debug
}


@test "$base: try-exec-func (bash) on existing function" {

  skip FIXME cleanup

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
