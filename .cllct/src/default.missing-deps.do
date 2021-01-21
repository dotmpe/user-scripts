#!/usr/bin/env bash
set -euo pipefail
docid="$(basename -- "$1" -lib.missing-deps)" &&
case "$docid" in
    default.lib-deps ) exit 21 ;; # refuse to build non lib
    "*.lib-deps" ) exit 22 ;; # refuse to build non lib
    * ) ;; esac

redo-ifchange "functions/$docid-lib.func-list"
while read caller
do
  test -n "$caller" || continue

  redo-ifchange "functions/$docid-lib/$caller.func-deps"
  test -e "functions/$docid-lib/$caller.func-deps" || continue
  while read callee
  do
    grep -q "^$callee$" functions/*.func-list || {
      test -x "$(which $callee)" && continue
      echo "$caller $callee"
    }
  done <"functions/$docid-lib/$caller.func-deps"
done <"functions/$docid-lib.func-list"
