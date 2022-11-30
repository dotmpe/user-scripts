#!/usr/bin/env bash
## Process all shell functions
# Created: 2020-08-31
set -euo pipefail

# Static analysis for Sh libs

# detect and track shell scripts

# TODO: rewrite targets using cllct tree to use new index in .meta/cache
build-ifchange \
  .meta/cache/source-sh.list \
  .meta/cache/sh-files.list \
  .meta/cache/sh-libs.list \
  .meta/cache/context.list

build-ifchange \
  $( cut -d"	" -f1 .meta/cache/sh-libs.list | xargs -I{} \
        echo .meta/src/functions/{}-lib.func-list )

build-ifchange \
  $( cut -d"	" -f1 .meta/cache/sh-libs.list | while read libid
    do
        test -n "$libid" || continue
        echo .meta/src/functions/$libid-lib.func-list

        while read func
        do
          test -n "$func" || continue
          echo .meta/src/functions/$libid-lib/$func.func-deps
        done <.meta/src/functions/$libid-lib.func-list

    done) \
  .meta/src/sh-stats
  # XXX: cleanup .meta/src/commands.list

#
