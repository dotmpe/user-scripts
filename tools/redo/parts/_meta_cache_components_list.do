#!/usr/bin/env bash

## List project components

# Build local index including local defs, and copy

test -d "$(dirname "$3")" || mkdir -p "$(dirname "$3")"

build-ifchange .meta/stat/index/components-local.list

{
  echo "# Generated on $(date --iso=min) from .meta/stat/index/components-local.list"
  echo "# at $3 and copied to .meta/stat/index/components.list"
  echo
  cat .meta/stat/index/components-local.list
} >"$3"

build-stamp <"$3"

build_copy_changed "$3" .meta/stat/index/components.list
