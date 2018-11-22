#!/bin/sh

logger_log() { echo "pre-load logger default $*" >&2; }
export LOG=logger_log
lib_load logger logger-theme
