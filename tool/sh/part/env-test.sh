#!/usr/bin/env bash

: "${default_lib:="main"}"
: "${testpath:="`pwd -P`/test"}"

# hostname-init()
hostnameid="$(hostname -s | tr 'A-Z.-' 'a-z__')"

# XXX:
#util_mode=load-ext . $scriptpath/tools/sh/init-wrapper.sh
#export ENV=./tools/sh/env.sh
export ENV_NAME=testing
