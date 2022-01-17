#!/usr/bin/env bash
## Process all shell functions
# Created: 2020-08-31
set -euo pipefail

# Static analysis for Sh libs

# detect and track shell scripts

build-ifchange \
  .meta/cache/sh-files.list \
  .meta/cache/sh-libs.list \
  .cllct/src/sh-libs.list \
  .meta/cache/context.list

build-ifchange \
  $( cut -d"	" -f1 .cllct/src/sh-libs.list | while read libid
    do
        test -n "$libid" || continue

        echo .cllct/src/functions/$libid-lib.func-list

        while read func
        do
          test -n "$func" || continue
          echo .cllct/src/functions/$libid-lib/$func.func-deps
        done <.cllct/src/functions/$libid-lib.func-list
    done) \
  .cllct/src/sh-stats
  # XXX: cleanup .cllct/src/commands.list

#
