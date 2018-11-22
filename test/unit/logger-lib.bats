#!/usr/bin/env bats

base=unit/logger.lib
load ../init

setup()
{
  init
}


@test "$base: logger-log TYPE TRGTS DESCR SRCS RET" {

  run logger_log
  { test_ok_nonempty 1
  } || stdfail
}

@test "$base: logger-stderr TYPE TRGTS DESCR SRCS RET" {

  run logger_stderr
  { test_ok_nonempty 1
  } || stdfail
}

@test "$base: logger-stderr-level NUM" {

  run logger_stderr_level
  { test_nok_empty
  } || stdfail 1.1.
  
  run logger_stderr_level 1
  { test_ok_nonempty 1 && test_lines "emerg" ;} || stdfail 2.1.

  run logger_stderr_level 7
  { test_ok_nonempty 1 && test_lines "debug" ;} || stdfail 2.2.
}

@test "$base: logger-demo" {

  logger_exit_threshold=0
  logger_log_threshold=7

  run logger_demo
  { test_ok_nonempty 7 && test_lines \
      "* Emergency*:*" \
      "* Critical*:*"
  } || stdfail 1.

  logger_log_threshold=0
  run logger_demo
  { test_ok_empty
  } || stdfail 2.0.

  logger_exit_threshold=1
  run logger_demo
  { test_nok_empty && test "$status" = "1"
  } || stdfail 2.1.

  logger_exit_threshold=2
  run logger_demo
  { test_nok_empty && test "$status" = "2"
  } || stdfail 2.2.

  logger_log_threshold=7
  run logger_demo
  { test_nok_nonempty 6 && test "$status" = "2"
  } || stdfail 3.1.

  logger_exit_threshold=3
  run logger_demo
  { test_nok_nonempty 5 && test "$status" = "3"
  } || stdfail 3.2.
}
