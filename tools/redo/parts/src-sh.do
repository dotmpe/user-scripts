#!/usr/bin/env bash
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
        echo .cllct/src/functions/$libid-lib.func-list

        while read func
        do
          echo .cllct/src/functions/$libid-lib/$func.func-deps
        done <.cllct/src/functions/$libid-lib.func-list
    done) \
  .cllct/src/commands.list .cllct/src/sh-stats

#
