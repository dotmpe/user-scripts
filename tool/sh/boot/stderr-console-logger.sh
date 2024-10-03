#!/bin/sh

lib_load logger logger-std && {

  test -n "${stderr_console_logger_sid-}" ||
    stderr_console_logger_sid="stderr-console-logger"

  logger_std_init "$stderr_console_logger_sid T\$(date +%H:%M:%S) P\${CTX_ID-}" &&
  true "${LOG:='logger_stderr'}"
}

#
