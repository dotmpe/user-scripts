#!/bin/sh

set -- "$@" "$REDO_PWD/$3" "$(basename "$3" .tap)"

# TODO: build tap report for other tests.
test -e "$5.bats" || exit 1

bats "$5.bats" | tee "$3"
redo-stamp <"$3"
grep -q '^not ok ' "$3" && false || true
