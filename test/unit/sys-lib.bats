#!/usr/bin/env bats

base=sys.lib
load ../init

setup()
{
  init 0 && lib_load sys && main_inc=$SHT_PWD/../var/sh-src-main-mytest-funcs.sh
}


@test "$base: incr VAR [AMOUNT]" {

  COUNT=2
  run incr COUNT 5
  test_ok_empty || stdfail "1."

  incr COUNT 5
  test $COUNT -eq 7 || stdfail "2. ($COUNT)"

}


@test "$base: trueish VALUE" {

  run trueish 1 ; test_ok_empty || stdfail 1.A.
  run trueish 0 ; test_nok_empty || stdfail 1.B.

  run trueish True ; test_ok_empty || stdfail 2.A.
  run trueish False ; test_nok_empty || stdfail 2.B.

  run trueish On ; test_ok_empty || stdfail 3.A.
  run trueish Off ; test_nok_empty || stdfail 3.B.

  run trueish Yes ; test_ok_empty || stdfail 4.A.
  run trueish No ; test_nok_empty || stdfail 4.B.

  run trueish - ; test_nok_empty || stdfail 5.A.
  run trueish "" ; test_nok_empty || stdfail 5.B.

}

@test "$base: not-trueish VALUE" {

  run not_trueish 1 ; test_nok_empty || stdfail 1.A.
  run not_trueish 0 ; test_ok_empty || stdfail 1.B.

  run not_trueish True ; test_nok_empty || stdfail 2.A.
  run not_trueish False ; test_ok_empty || stdfail 2.B.

  run not_trueish On ; test_nok_empty || stdfail 3.A.
  run not_trueish Off ; test_ok_empty || stdfail 3.B.

  run not_trueish Yes ; test_nok_empty || stdfail 4.A.
  run not_trueish No ; test_ok_empty || stdfail 4.B.

  run not_trueish - ; test_ok_empty || stdfail 5.A.
  run not_trueish "" ; test_ok_empty || stdfail 5.B.

}

@test "$base: falseish VALUE" {

  run falseish 1 ; test_nok_empty || stdfail 1.A.
  run falseish 0 ; test_ok_empty || stdfail 1.B.

  run falseish True ; test_nok_empty || stdfail 2.A.
  run falseish False ; test_ok_empty || stdfail 2.B.

  run falseish On ; test_nok_empty || stdfail 3.A.
  run falseish Off ; test_ok_empty || stdfail 3.B.

  run falseish Yes ; test_nok_empty || stdfail 4.A.
  run falseish No ; test_ok_empty || stdfail 4.B.

  run falseish - ; test_nok_empty || stdfail 5.A.
  run falseish "" ; test_nok_empty || stdfail 5.B.
}

@test "$base: not-falseish VALUE" {

  run not_falseish 1 ; test_ok_empty || stdfail 1.A.
  run not_falseish 0 ; test_nok_empty || stdfail 1.B.

  run not_falseish True ; test_ok_empty || stdfail 2.A.
  run not_falseish False ; test_nok_empty || stdfail 2.B.

  run not_falseish On ; test_ok_empty || stdfail 3.A.
  run not_falseish Off ; test_nok_empty || stdfail 3.B.

  run not_falseish Yes ; test_ok_empty || stdfail 4.A.
  run not_falseish No ; test_nok_empty || stdfail 4.B.

  run not_falseish - ; test_ok_empty || stdfail 5.A.
  run not_falseish "" ; test_ok_empty || stdfail 5.B.
}


@test "$base: cmd-exists NAME" {

  run cmd_exists "ls"
  test_ok_empty || stdfail "A."

  run cmd_exists ""
  test_nok_empty || stdfail "B.1."
  
  lib_load os

  run which "$(get_uuid)"
  test_nok_empty || stdfail "B.2."

  run cmd_exists "$(get_uuid)"
  test_nok_empty || stdfail "B.3."
}


@test "$base: func-exists NAME" {

  myfunc() { false; }

  run func_exists myfunc
  test_ok_empty || stdfail A.

  lib_load os

  run func_exists $(get_uuid)
  test_nok_empty || stdfail B.
}


# util / Try-Exec

@test "$base: try-exec-func on existing function" {

  #lib_load os str logger-std

  . $main_inc

  export verbosity=4

  run try_exec_func mytest_function
  { test $status -eq 0 && fnmatch "mytest" "${lines[*]}"
  } || stdfail

}

@test "$base: try-exec-func on non-existing function" {

  run try_exec_func no_such_function
  test $status -eq 1

}
