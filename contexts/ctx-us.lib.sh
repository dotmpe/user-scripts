#!/usr/bin/env bash

ctx_us_lib_load() { true; }

ctx__U_S__source_dir="$(dirname "${BASH_SOURCE[0]}")"
ctx_us_lib_init()
{
  true "${U_S:="$ctx__U_S__source_dir"}"
}

ctx__UserScript__init_env()
{
  fnmatch ""
    unset -f lib_load
    ENV_DEV=1 CWD=$PWD . $U_S/tools/sh/init.sh
    CTX_P+=" @UserScript"
  #}
}
