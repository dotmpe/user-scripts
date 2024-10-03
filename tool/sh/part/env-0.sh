#!/usr/bin/env bash

# Env without any pre-requisites.


: "${LOG:="$CWD/tools/sh/log.sh"}"

: "${verbosity:=4}"
: "${SCRIPTPATH:=}"
: "${CWD:="$PWD"}"
: "${DEBUG:=}"
: "${OUT:="echo"}"
: "${PS1:=}"
: "${BASHOPTS:=}" || true
: "${BASH_ENV:=}"
: "${shopts:="$-"}"
: "${SCRIPT_SHELL:="$SHELL"}"
: "${TAB_C:="	"}"
TAB_C="	"
#: "${TAB_C:="`printf '\t'`"}"
#: "${NL_C:="`printf '\r\n'`"}"

test -n "${DEBUG:-}" && : "${keep_going:=false}" || : "${keep_going:=true}"

: "${USER:="$(whoami)"}"

: "${NS_NAME:="dotmpe"}"
: "${DOCKER_NS:="$NS_NAME"}"
: "${scriptname:="`basename -- "$0"`"}"
