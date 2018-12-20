#!/bin/ash

# XXX: where-to
#set -o pipefail
#set -o errexit
#set -o nounset

: "${script_util:=$CWD/tools/sh}"
: "${ci_util:=$CWD/tools/ci}"
export script_util ci_util
