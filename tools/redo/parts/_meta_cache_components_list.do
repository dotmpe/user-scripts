#!/usr/bin/env bash

build-ifchange .meta/stat/index/components-local.list
cat .meta/stat/index/components-local.list >"$3"
cp "$3" .meta/stat/index/components.list
build-stamp <"$3"
