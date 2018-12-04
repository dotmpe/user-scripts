#!/bin/sh

lib_load logger-std &&
logger_std_init "stderr-console-logger \$(date +%H:%M:%S)" &&
export LOG=logger_stderr
