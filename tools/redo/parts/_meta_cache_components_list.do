#!/usr/bin/env bash

## List project components

# Build local index including local defs, and copy

test -d "$(dirname "$3")" || mkdir -p "$(dirname "$3")"

set -- "$@" .meta/stat/index/components-local.list

build-ifchange "$4"

{
  echo "# Generated on $(date --iso=min) from $4"
  echo "# at $3 and copied to .meta/stat/index/components.list"
  echo
  cat "$4"
} >"$3"

build-stamp <"$3"

# Copy the file so it can be managed (by another system) as standalone
# metadata
build_copy_changed "$3" .meta/stat/index/components.list
