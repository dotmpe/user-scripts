#!/usr/bin/env bash
# Created: 2020-08-31
set -euo pipefail

# Static analysis for Sh libs

# detect and track shell scripts
build-ifchange .meta/cache/sh-files.list || {
    build-keep-going || return
  }

# sh-libs is a subset of sh-files, 
build-ifchange .meta/cache/sh-libs.list || {
    build-keep-going || return
  }

# TODO: update .meta/stat/index/context from cache (incl. above files)
build-ifchange .meta/cache/context.list || {
    build-keep-going || return
  }


build-ifchange .cllct/src/sh-libs.list || {
    build-keep-going || return
  }

cut -d"	" -f1 .cllct/src/sh-libs.list | while read libid
do
    build-ifchange .cllct/src/functions/$libid-lib.func-list || {
      build-keep-going || return
    }
    while read func
    do
      build-ifchange .cllct/src/functions/$libid-lib/$func.func-deps || {
        build-keep-going || return
      }
    done <.cllct/src/functions/$libid-lib.func-list
done

build-ifchange .cllct/src/commands.list .cllct/src/sh-stats || {
    build-keep-going || return
  }
{ echo "Updated Sh stats"
  cat .cllct/src/sh-stats
} >&2
#
