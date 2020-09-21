#!/usr/bin/env bash

build-ifchange .meta/stat/index/components-local.list
test -d "$(dirname "$3")" || mkdir -p "$(dirname "$3")"
cat .meta/stat/index/components-local.list >"$3"
cp "$3" .meta/stat/index/components.list
build-stamp <"$3"
