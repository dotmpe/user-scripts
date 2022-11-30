#!/usr/bin/env bash

sh_mode strict dev


#build_env_declare us-libs &&
#lib_require match || return


bats=$(basename "$1" .tap)

case "$bats" in
  baseline-* ) bats=test/baseline/${bats/baseline-}.bats ;;
  unit-* ) bats=test/unit/${bats/unit-}.bats ;;
esac

bats "$bats" |
if test ${build_ci_tests_quiet:-${quiet-0}} -eq 1
then cat >"$3"
else tee "$3" | ./tools/sh/bats-colorize.sh >&2; fi
build-stamp <"$3"

grep -qvi '^not ok' "$3"
# Id: U-S:
