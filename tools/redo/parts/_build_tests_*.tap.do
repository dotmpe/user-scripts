#!/usr/bin/env bash
build-ifchange .meta/cache/components.list
lib_require match
set -o noglob; set -- "$@" $(build_fetch_component "$1"); set +o noglob
set -- "$@" $(glob_spec_var "$5" "$1")
set -- "$@" $(echo "$6" | sed 's/%/'"$7"'/')
test -d $(dirname "$1") || mkdir -p $(dirname "$1")
test -e "$8" || exit 20

local r
{ bats "$8"  || r=$?; } |
if test ${build_ci_tests_quiet:-${quiet-0}} -eq 1
then cat >"$3"
else tee "$3" | ./tools/sh/bats-colorize.sh >&2; fi
build-stamp <"$3"

return ${r:-}
# Id: U-S:
