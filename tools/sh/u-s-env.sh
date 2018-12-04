#!/bin/sh

# Look at host / env and export u-s install type

#if usr
#elif usr-local

#elif dev|basher
#test -n "$U_S" || U_S="$(basher package-path ...)"
test -n "$U_S" || U_S="$(dirname "$(dirname "$(realpath "$0")")")"
#else dev-local
#test -n "$U_S" || U_S="$(pwd -P)"

U_S_ENV=dev
export U_S_ENV U_S
