#!/usr/bin/env bats

base=unit/logger.lib
load ../init

setup()
{
  init && lib_load logger-std
}


@test "$base: logger-log TYPE TRGTS DESCR SRCS RET" {

  run logger_log
  { test_nok_empty && test $status -eq 98
  } || stdfail
}

@test "$base: logger-stderr TYPE TRGTS DESCR SRCS RET" {

  run logger_stderr
  { test_nok_empty && test $status -eq 98
  } || stdfail
}

@test "$base: logger-stderr-level NUM" {

  run log_level_name
  { test_nok_empty
  } || stdfail 1.1.
  
  run log_level_name 1
  { test_ok_nonempty 1 && test_lines "emerg" ;} || stdfail 2.1.

  run log_level_name 7
  { test_ok_nonempty 1 && test_lines "debug" ;} || stdfail 2.2.
}

@test "$base: stderr-demo" {

  run stderr_demo
  test_ok_nonempty || stdfail
}

@test "$base: logger-demo" {

  logger_exit_threshold=0
  logger_log_threshold=7

  run logger_demo
  { test_ok_nonempty 7 && test_lines \
      "*Emergency*:*" \
      "*Critical*:*"
  } || stdfail 1.

  logger_log_threshold=0
  run logger_demo
  { test_ok_empty
  } || stdfail 2.0.

  logger_exit_threshold=1
  run logger_demo
  { test_nok_empty && test "$status" = "255"
  } || stdfail 2.1.

  logger_exit_threshold=2
  run logger_demo
  { test_nok_empty && test "$status" = "254"
  } || stdfail 2.2.

  logger_log_threshold=7
  run logger_demo
  { test_nok_nonempty 6 && test "$status" = "254"
  } || stdfail 3.1.

  logger_exit_threshold=3
  run logger_demo
  { test_nok_nonempty 5 && test "$status" = "253"
  } || stdfail 3.2.
}
