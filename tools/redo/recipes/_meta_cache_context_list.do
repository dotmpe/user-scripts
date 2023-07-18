#!/usr/bin/env bash

## Maintain local context.list index

# Convert indices to contexts.
# build context.list from context-local.list

# TODO: update .meta/stat/index/context from cache (incl. sh-files, s-libs files)

context_local=$(dirname "$1")/$(basename "$1" .list)-local.list
redo-ifchange \
  .meta/cache/sh-files.list \
  $context_local

#DEBUG=${REDO_DEBUG-${DEBUG-0}} CWD=$CWD \
#  $CWD/tools/bash/build.sh -- \
#    journal-context-status-tab -- \
#      $CWD/.meta/cache/entries.list

echo
test ! -e $context_local || cat $context_local

redo-stamp

# Id: U-S:tools/redo/recipes/_meta_cache_context.list.do             ex:ft=bash:
