#!/usr/bin/env bash
build-ifchange .meta/cache/components.list
lib_require match
set -o noglob; set -- "$@" $(build_rule_fetch "$1"); set +o noglob
set -- "$@" $(glob_spec_var "$5" "$1")
set -- "$@" $(echo "$6" | sed 's/%/'"$7"'/')
test -d $(dirname "$1") || mkdir -p $(dirname "$1")
test -e "$8" || exit 20

bats "$8" |
if test ${build_ci_tests_quiet:-${quiet-0}} -eq 1
then cat >"$3"
else tee "$3" | ./tools/sh/bats-colorize.sh >&2; fi
build-stamp <"$3"

grep -qvi '^not ok' "$3"
# Id: U-S:
