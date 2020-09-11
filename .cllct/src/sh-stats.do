#!/usr/bin/env bash
set -euo pipefail

redo-ifchange \
    $REDO_BASE/.meta/cache/sh-files.list \
    sh-libs.list \
    functions/*.func-list \
    functions/*/*.func-deps

echo "Build cache files line counts:"
wc -l \
    $REDO_BASE/.meta/cache/sh-files.list \
    sh-libs.list \
    functions/*.func-list \
    functions/*/*.func-deps

echo "Sh files: $( sort -u sh-libs.list | wc -l | awk '{print $1}' )"
echo "Sh libs: $( cut -d'\t' -f 1 sh-libs.list | sort -u | wc -l | awk '{print $1}' )"
echo "Dependencies: $( sort -u functions/*/*.func-deps | wc -l | awk '{print $1}' )"
#
