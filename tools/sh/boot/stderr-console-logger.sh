#!/bin/sh

lib_load logger logger-std && {

  logger_std_init "stderr-console-logger T\$(date +%H:%M:%S)" &&
  LOG=logger_stderr
}

#
