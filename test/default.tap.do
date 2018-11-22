#!/bin/sh

set -- "$@" "$(dirname "$1")/$(basename "$1" .tap)"
test -e "$4.bats" || exit 20

# move to project dir before testing for ease of managing paths
set -- "$REDO_PWD/$1" "$REDO_PWD/$2" "$REDO_PWD/$3" "$REDO_PWD/$4"
cd "$REDO_BASE"
test -e "$4.bats" || exit 30

bats "$4.bats" | tee "$3" | $HOME/bin/bats-colorize.sh >&2
redo-stamp <"$3"
grep -q '^not\ ok\ ' "$3" && false || true
