#!/usr/bin/env bash

# Routines used to help during CI runs

test -z "${ci_util_:-}" && ci_util_=1 || exit 98 # Recursion

test -n "${sh_util_:-}" || {
  . "${sh_tools:="${CWD:="$PWD"}/tools/sh"}/util.sh"
}

sh_include std-ci-helper

# Id: user-scripts/0.0.2-dev tools/ci/util.sh
